#!/bin/bash

[[ "$TRACE" = "yes" ]] && set -x
set -e

if [[ -z "$REGISTRATOR_REGISTRY_URI" ]]; then
    echo >&2 "Error: missing required 'REGISTRATOR_REGISTRY_URI' environment variable."
    exit 1
fi

echo "==> Using registry URI '${REGISTRATOR_REGISTRY_URI}'."

REGISTRATOR_CLEANUP=
if [[ "$REGISTRATOR_CLEANUP_ENABLED" = "yes" ]]; then
  REGISTRATOR_CLEANUP="-cleanup"
  echo "==> Expecting registrator to clean up dangling services, setting cleanup option..."
fi

REGISTRATOR_RESYNC=
if [[ -n "$REGISTRATOR_RESYNC_SECONDS" ]]; then
  REGISTRATOR_RESYNC="-resync ${REGISTRATOR_RESYNC_SECONDS}"
  echo "==> Expecting registrator to resync every '${REGISTRATOR_RESYNC_SECONDS}' seconds, setting resync option..."
fi

REGISTRATOR_TTL=
if [[ -n "$REGISTRATOR_TTL_SECONDS" ]]; then
  REGISTRATOR_TTL="-ttl ${REGISTRATOR_TTL_SECONDS}"
  echo "==> Expecting registrator to set service TTL to '${REGISTRATOR_TTL_SECONDS}' seconds, setting ttl option..."
fi

REGISTRATOR_TTL_REFRESH=
if [[ -n "$REGISTRATOR_TTL_REFRESH_SECONDS" ]]; then
  REGISTRATOR_TTL_REFRESH="-ttl ${REGISTRATOR_TTL_REFRESH_SECONDS}"
  echo "==> Expecting registrator to refresh service TTL every '${REGISTRATOR_TTL_REFRESH_SECONDS}' seconds, setting ttl-refresh option..."
fi

exec /registrator/bin/registrator \
    "${REGISTRATOR_CLEANUP}" \
    "${REGISTRATOR_RESYNC}" \
    "${REGISTRATOR_TTL}" \
    "${REGISTRATOR_TTL_REFRESH}" \
    "${REGISTRATOR_REGISTRY_URI}"
