#!/usr/bin/env bash
# Smoke test for dgcosenza/firefox: verifies Mozilla Firefox version,
# tini PID 1, non-root abc desktop processes, HTTP Basic Auth enforcement
# on :3001 (401 without creds, 200 with creds), and negative healthcheck.
set -euo pipefail

IMAGE="${1:-dgcosenza/firefox:ci-candidate}"
NAME="firefox-ci-smoke-$$"
TMPCONF="$(mktemp -d)"
chmod 777 "$TMPCONF"

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run --rm --user 0:0 -v "${TMPCONF}:/cleanup" --entrypoint /bin/sh "$IMAGE" -c 'rm -rf /cleanup/* /cleanup/.[!.]*' >/dev/null 2>&1 || true
  rm -rf "$TMPCONF" 2>/dev/null || true
}
trap cleanup EXIT

# 1. Verify official Mozilla Firefox binary version
FF_VER="$(docker run --rm --entrypoint firefox "$IMAGE" --version)"
echo "Firefox binary: ${FF_VER}"
printf '%s' "$FF_VER" | grep -qE 'Mozilla Firefox [0-9]+\.[0-9]+'

# 2. Boot container with Basic Auth enabled and no-new-privileges
SMOKE_USER="testuser"
SMOKE_PASS="smoke-$(date +%s)-$$"
docker run -d --name "$NAME" \
  --security-opt no-new-privileges:true \
  --shm-size 512m \
  -p 127.0.0.1:13001:3001 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e CUSTOM_USER="$SMOKE_USER" \
  -e PASSWORD="$SMOKE_PASS" \
  -e CHROME_CLI="about:blank" \
  -v "${TMPCONF}:/config" \
  "$IMAGE"

# Wait for Docker HEALTHCHECK to report healthy
HEALTHY=0
for _ in $(seq 1 90); do
  STATUS="$(docker inspect --format '{{.State.Health.Status}}' "$NAME" 2>/dev/null || echo "missing")"
  if [ "$STATUS" = "healthy" ]; then
    HEALTHY=1
    break
  fi
  if [ "$STATUS" = "missing" ] || [ "$(docker inspect --format '{{.State.Running}}' "$NAME" 2>/dev/null || echo false)" != "true" ]; then
    echo "ERROR: firefox container exited prematurely (status=${STATUS}):" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  sleep 1
done
if [ "$HEALTHY" -ne 1 ]; then
  echo "ERROR: Container did not become healthy within 90s (status=${STATUS:-unknown})" >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi

# 3. Wait for HTTPS :3001 to return 401 (Basic Auth enforced)
READY=0
for _ in $(seq 1 30); do
  if ! docker ps -q --filter "name=^/${NAME}$" | grep -q .; then
    echo "ERROR: firefox container exited prematurely:" >&2
    docker logs "$NAME" >&2 || true
    exit 1
  fi
  CODE="$(docker exec "$NAME" curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:3001/ 2>/dev/null || true)"
  if [ "$CODE" = "401" ]; then
    READY=1
    break
  fi
  sleep 1
done
if [ "$READY" -ne 1 ]; then
  echo "ERROR: expected HTTP 401 on https://127.0.0.1:3001/ (got ${CODE:-none})" >&2
  docker logs "$NAME" >&2 || true
  exit 1
fi

# 4. Verify authenticated request returns HTTP 200 with noVNC landing page
AUTH_CODE="$(curl -sk -u "${SMOKE_USER}:${SMOKE_PASS}" -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:13001/)"
test "$AUTH_CODE" = "200"

# 5. Verify tini PID 1 and non-root abc processes (Xtigervnc, openbox, websockify, nginx worker)
PID1_COMM="$(docker exec "$NAME" cat /proc/1/comm)"
test "$PID1_COMM" = "tini"
docker exec "$NAME" ps -eo user,comm | grep -qE '^abc[[:space:]]+Xtigervnc$'
docker exec "$NAME" ps -eo user,comm | grep -qE '^abc[[:space:]]+openbox$'
docker exec "$NAME" ps -eo user,comm | grep -qE '^abc[[:space:]]+nginx$'

# 6. Run exact healthcheck command and verify negative closed-port check fails
docker exec "$NAME" sh -c "curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:3001/ | grep -qE '^(200|301|302|401)$'"
if docker exec "$NAME" sh -c "curl -sk -o /dev/null -w '%{http_code}' --max-time 3 https://127.0.0.1:59999/ | grep -qE '^(200|301|302|401)$'"; then
  echo "ERROR: healthcheck unexpectedly passed on closed port 59999" >&2
  exit 1
fi

echo "Smoke test passed (pid1=${PID1_COMM}, unauth=${CODE}, auth=${AUTH_CODE}, firefox=${FF_VER})."
