#!/bin/bash

[[ "$TRACE" = "yes" ]] && set -x
set -e

CONSUL_BIND=""
if [[ -n "$CONSUL_BIND_INTERFACE" ]]; then
  CONSUL_BIND_ADDRESS=$(ip -o -4 addr list "$CONSUL_BIND_INTERFACE" | head -n1 | awk '{print $4}' | cut -d/ -f1)
  if [[ -z "$CONSUL_BIND_ADDRESS" ]]; then
    echo "Could not find IP for interface '$CONSUL_BIND_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_BIND="-bind=$CONSUL_BIND_ADDRESS"
  echo "==> Found address '$CONSUL_BIND_ADDRESS' for interface '$CONSUL_BIND_INTERFACE', setting bind option..."
fi

CONSUL_CLIENT=""
if [[ -n "$CONSUL_CLIENT_INTERFACE" ]]; then
  CONSUL_CLIENT_FOUND_ADDRESS=$(ip -o -4 addr list "$CONSUL_CLIENT_INTERFACE" | head -n1 | awk '{print $4}' | cut -d/ -f1)
  if [[ -z "$CONSUL_CLIENT_FOUND_ADDRESS" ]]; then
    echo "Could not find IP for interface '$CONSUL_CLIENT_INTERFACE', exiting"
    exit 1
  fi

  CONSUL_CLIENT="-client=$CONSUL_CLIENT_FOUND_ADDRESS"
  echo "==> Found address '$CONSUL_CLIENT_FOUND_ADDRESS' for interface '$CONSUL_CLIENT_INTERFACE', setting client option..."
fi

if [[ -n "$CONSUL_CLIENT_ADDRESS" ]]; then
  CONSUL_CLIENT="-client=$CONSUL_CLIENT_ADDRESS"
  echo "==> Client address '$CONSUL_CLIENT_ADDRESS' provided, setting client option..."
fi

CONSUL_RETRY_JOIN=()
if [[ -n "$CONSUL_EC2_AUTO_JOIN_TAG_KEY" ]]; then
  CONSUL_RETRY_JOIN=('-retry-join' "provider=aws tag_key=${CONSUL_EC2_AUTO_JOIN_TAG_KEY} tag_value=${CONSUL_EC2_AUTO_JOIN_TAG_VALUE}")
  echo "==> Found EC2 auto-join tag key '$CONSUL_EC2_AUTO_JOIN_TAG_KEY' and value '$CONSUL_EC2_AUTO_JOIN_TAG_VALUE', setting retry-join option..."
fi

if [[ -n "$CONSUL_SERVER_ADDRESSES" ]]; then
  for CONSUL_SERVER_ADDRESS in ${CONSUL_SERVER_ADDRESSES//,/ }; do
    CONSUL_RETRY_JOIN+=('-retry-join' "$CONSUL_SERVER_ADDRESS")
  done
  echo "==> Joining consul server(s) at '$CONSUL_SERVER_ADDRESSES', setting retry-join option..."
fi

CONSUL_BOOTSTRAP_EXPECT=""
if [[ -n "$CONSUL_EXPECTED_SERVERS" ]]; then
  CONSUL_BOOTSTRAP_EXPECT="-bootstrap-expect ${CONSUL_EXPECTED_SERVERS}"
  echo "==> Expecting '$CONSUL_EXPECTED_SERVERS' servers, setting bootstrap-expect option..."
fi

CONSUL_UI=""
if [[ "${CONSUL_ENABLE_UI}" = "yes" ]]; then
  CONSUL_UI="-ui"
  echo "==> Found request to enable UI, setting ui option..."
fi

CONSUL_DATA_DIR=/opt/consul/data
CONSUL_CONFIG_DIR=/opt/consul/config

if [[ -n "$CONSUL_LOCAL_CONFIG" ]]; then
	echo "$CONSUL_LOCAL_CONFIG" > "$CONSUL_CONFIG_DIR/local.json"
fi

if [[ "${1:0:1}" = '-' ]]; then
    set -- /opt/consul/bin/consul "$@"
fi

if [[ "$1" = 'agent' ]]; then
    shift
    set -- /opt/consul/bin/consul agent \
        -data-dir="$CONSUL_DATA_DIR" \
        -config-dir="$CONSUL_CONFIG_DIR" \
        ${CONSUL_BIND} \
        ${CONSUL_CLIENT} \
        ${CONSUL_UI} \
        ${CONSUL_BOOTSTRAP_EXPECT} \
        "${CONSUL_RETRY_JOIN[@]}" \
        "$@"
elif [[ "$1" = 'version' ]]; then
    set -- /opt/consul/bin/consul "$@"
elif /opt/consul/bin/consul --help "$1" 2>&1 | grep -q "consul $1"; then
    set -- /opt/consul/bin/consul "$@"
fi

if [[ "$1" = '/opt/consul/bin/consul' && -z "${CONSUL_DISABLE_PERM_MGMT+x}" ]]; then
    if [[ "$(stat -c %u /opt/consul/data)" != "$(id -u consul)" ]]; then
        chown consul:consul /opt/consul/data
    fi
    if [[ "$(stat -c %u /opt/consul/config)" != "$(id -u consul)" ]]; then
        chown consul:consul /opt/consul/config
    fi

    if [[ ! -z "${CONSUL_ALLOW_PRIVILEGED_PORTS+x}" ]]; then
        setcap "cap_net_bind_service=+ep" /opt/consul/bin/consul
    fi

    shift
    set -- su-exec consul:consul /opt/consul/bin/consul "$@"
fi

echo "$@"

exec "$@"