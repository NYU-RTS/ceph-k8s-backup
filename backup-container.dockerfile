FROM ubuntu:22.04

RUN apt-get update -yy && \
    apt-get install -yy curl ca-certificates bzip2 ceph-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ARG TARGETPLATFORM

ARG TINI_VERSION=0.19.0

RUN if [ ${TARGETPLATFORM} = "linux/amd64" ]; then SUFFIX=amd64 ; HASH=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c; \
    elif [ ${TARGETPLATFORM} = "linux/arm64" ]; then SUFFIX=arm64 ; HASH=07952557df20bfd2a95f9bef198b445e006171969499a1d361bd9e6f8e5e0e81; \
    else echo "no URL for $(TARGETPLATFORM)"; exit 1; fi && \
    curl -Lo /tini https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-${SUFFIX} && \
    printf "${HASH}  /tini\\n" | sha256sum -c && \
    chmod +x /tini

ARG RESTIC_VERSION=0.18.0

RUN if [ ${TARGETPLATFORM} = "linux/amd64" ]; then SUFFIX=linux_amd64; HASH=98f6dd8bf5b59058d04bfd8dab58e196cc2a680666ccee90275a3b722374438e; \
    elif [ ${TARGETPLATFORM} = "linux/arm64" ]; then SUFFIX=linux_arm64; HASH=ce18179c25dc5f2e33e3c233ba1e580f9de1a4566d2977e8d9600210363ec209; \
    elif [ ${TARGETPLATFORM} = "linux/riscv64" ]; then SUFFIX=linux_riscv64; HASH=855a27d8f7d1ce7deec3beaea03a348f88449c69922cc3d65c34d8be645ee3a5; \
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
