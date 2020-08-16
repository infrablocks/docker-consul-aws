FROM infrablocks/alpine-aws-s3-config:0.18.0

# Inspired by hashicorp/docker-consul

ENV CONSUL_VERSION=1.7.7
ENV HASHICORP_RELEASES=https://releases.hashicorp.com

RUN addgroup consul && \
    adduser -S -G consul consul

RUN set -eux && \
    apk add --no-cache ca-certificates gnupg libcap openssl su-exec iputils && \
    gpg --keyserver pool.sks-keyservers.net --recv-keys 91A6E7F85D05C65630BEF18951852D87348FFC4C && \
    mkdir -p /tmp/build && \
    cd /tmp/build && \
    apkArch="$(apk --print-arch)" && \
    case "${apkArch}" in \
        aarch64) consulArch='arm64' ;; \
        armhf) consulArch='arm' ;; \
        x86) consulArch='386' ;; \
        x86_64) consulArch='amd64' ;; \
        *) echo >&2 "error: unsupported architecture: ${apkArch} (see ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/)" && exit 1 ;; \
    esac && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS && \
    wget ${HASHICORP_RELEASES}/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_SHA256SUMS.sig && \
    gpg --batch --verify consul_${CONSUL_VERSION}_SHA256SUMS.sig consul_${CONSUL_VERSION}_SHA256SUMS && \
    grep consul_${CONSUL_VERSION}_linux_${consulArch}.zip consul_${CONSUL_VERSION}_SHA256SUMS | sha256sum -c && \
    unzip -d /bin consul_${CONSUL_VERSION}_linux_${consulArch}.zip && \
    cd /tmp && \
    rm -rf /tmp/build && \
    apk del gnupg openssl && \
    rm -rf /root/.gnupg && \
    consul version

RUN mkdir -p /consul/bin && \
    mkdir -p /consul/data && \
    mkdir -p /consul/config && \
    chown -R consul:consul /consul

RUN test -e /etc/nsswitch.conf || echo 'hosts: files dns' > /etc/nsswitch.conf

VOLUME /consul/data

EXPOSE 8300 8301 8301/udp 8302 8302/udp 8500 8600 8600/udp

COPY docker-entrypoint.sh /consul/bin/docker-entrypoint.sh

ENV STARTUP_SCRIPT_PATH=/consul/bin/docker-entrypoint.sh
