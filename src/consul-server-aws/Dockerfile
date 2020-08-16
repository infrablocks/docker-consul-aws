ARG BASE_IMAGE_VERSION
FROM infrablocks/consul-aws:$BASE_IMAGE_VERSION

COPY docker-entrypoint.sh /opt/consul/bin/server-docker-entrypoint.sh

ENV STARTUP_SCRIPT_PATH=/opt/consul/bin/server-docker-entrypoint.sh
