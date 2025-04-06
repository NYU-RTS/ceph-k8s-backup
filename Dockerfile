FROM --platform=$BUILDPLATFORM python:3.13 AS deps

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && /root/.local/bin/poetry config virtualenvs.create false && \
    /root/.local/bin/poetry self add poetry-plugin-export

# Copy Poetry data
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY pyproject.toml poetry.lock ./

# Generate requirements list
RUN /root/.local/bin/poetry export -o requirements.txt


FROM python:3.13

# Install rbd
RUN apt-get update && \
    apt-get install -yy ceph-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG TARGETPLATFORM

ARG TINI_VERSION=0.19.0

RUN if [ ${TARGETPLATFORM} = "linux/amd64" ]; then SUFFIX=amd64 ; HASH=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c; \
    elif [ ${TARGETPLATFORM} = "linux/arm64" ]; then SUFFIX=arm64 ; HASH=07952557df20bfd2a95f9bef198b445e006171969499a1d361bd9e6f8e5e0e81; \
    else echo "no URL for ${TARGETPLATFORM}"; exit 1; fi && \
    curl -Lo /tini https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${SUFFIX} && \
    printf "${HASH}  /tini\\n" | sha256sum -c && \
    chmod +x /tini

# Install requirements
COPY --from=deps /usr/src/app/requirements.txt /requirements.txt
RUN pip --disable-pip-version-check install --no-cache-dir -r /requirements.txt

# Set up app
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
COPY ceph_backup ./ceph_backup
RUN printf -- '#!/bin/sh\npython3 -c "from ceph_backup.backup import main; main()" "$@"' > /usr/local/bin/ceph-backup && \
    printf -- '#!/bin/sh\npython3 -c "from ceph_backup.metrics import main; main()" "$@"' > /usr/local/bin/ceph-backup-metrics && \
    chmod +x /usr/local/bin/ceph-backup /usr/local/bin/ceph-backup-metrics

# Set up user
RUN mkdir -p /usr/src/app/home && \
    useradd -d /usr/src/app/home -s /usr/sbin/nologin -u 998 appuser && \
    chown appuser /usr/src/app/home

ENV PYTHONFAULTHANDLER=1

USER 998
ENTRYPOINT ["/tini", "--", "/bin/bash", "-c", "if [ x\"$OTEL_TRACES_EXPORTER\" != x ]; then exec opentelemetry-instrument \"$@\"; else exec \"$@\"; fi", "--"]
CMD ["ceph-backup"]
