#!/bin/sh
set -eu

apk add --no-cache curl jq >/dev/null

URL="http://k8s-openbao.openbao.svc:8200/v1/sys/health"
BODY=$(mktemp)
STATUS=$(curl -s -o "$BODY" -w "%{http_code}" "$URL")
SEALED=$(jq -r '.sealed' "$BODY")

if [ "$SEALED" = "true" ]; then
  echo "FAIL: OpenBao is SEALED"
  exit 1
fi

if [ "$STATUS" != "200" ]; then
  echo "FAIL: expected status 200 (active, unsealed) from $URL, got $STATUS"
  exit 1
fi

echo "PASS: $URL returned 200, unsealed"
