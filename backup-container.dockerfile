FROM ubuntu:22.04

ENV TINI_VERSION=v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini

RUN apt-get update -yy && \
    apt-get install -yy curl ca-certificates bzip2 ceph-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG RESTIC_VERSION=0.17.3
ARG TARGETPLATFORM

RUN if [ ${TARGETPLATFORM} = "linux/amd64" ]; then SUFFIX=linux_amd64; HASH=5097faeda6aa13167aae6e36efdba636637f8741fed89bbf015678334632d4d3; \
    elif [ ${TARGETPLATFORM} = "linux/arm64" ]; then SUFFIX=linux_arm64; HASH=db27b803534d301cef30577468cf61cb2e242165b8cd6d8cd6efd7001be2e557; \
    else echo "no URL for $(TARGETPLATFORM)"; exit 1; fi && \
    curl -Lo /tmp/restic.bz2 https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_${SUFFIX}.bz2 && \
    printf "${HASH}  /tmp/restic.bz2\\n" | sha256sum -c && \
    bunzip2 < /tmp/restic.bz2 > /usr/local/bin/restic && \
    rm /tmp/restic.bz2 && \
    chmod +x /usr/local/bin/restic

ARG QCOW2_WRITER_VERSION=0.1.0
ARG QCOW2_WRITER_DL_HASH=7c6ec8277e31498e5e73ca811c2b5feca7dce4d460b0fee695c4ba74ec63ecde
RUN curl -Lo /tmp/streaming-qcow2-writer_linux_amd64.bz2 https://github.com/NYU-ITS/streaming-qcow2-writer/releases/download/v${QCOW2_WRITER_VERSION}/streaming-qcow2-writer_${QCOW2_WRITER_VERSION}_linux_amd64.bz2 && \
    printf "${QCOW2_WRITER_DL_HASH}  /tmp/streaming-qcow2-writer_linux_amd64.bz2\\n" | sha256sum -c && \
    bunzip2 < /tmp/streaming-qcow2-writer_linux_amd64.bz2 > /usr/local/bin/streaming-qcow2-writer && \
    rm /tmp/streaming-qcow2-writer_linux_amd64.bz2 && \
    chmod +x /usr/local/bin/streaming-qcow2-writer

ENTRYPOINT ["/tini", "--"]
