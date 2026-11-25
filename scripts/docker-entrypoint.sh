#!/usr/bin/env bash
set -euo pipefail

PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
DISPLAY="${DISPLAY:-:1}"
SCREEN_WIDTH="${SCREEN_WIDTH:-1440}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-900}"
SCREEN_DEPTH="${SCREEN_DEPTH:-24}"
TITLE="${TITLE:-Firefox}"
export HOME="/config"
export DISPLAY

if [ "$(id -u)" -eq 0 ]; then
  if [ "$(id -g abc)" != "$PGID" ]; then
    groupmod -o -g "$PGID" abc
  fi
  if [ "$(id -u abc)" != "$PUID" ]; then
    usermod -o -u "$PUID" abc
  fi
fi

mkdir -p \
  /config/.config/openbox \
  /config/.mozilla \
  /config/Desktop \
  /config/Downloads \
  /config/ssl \
  /run/firefox-web \
  /tmp/.X11-unix \
  /var/lib/nginx/body \
  /var/log/nginx

chmod 1777 /tmp/.X11-unix

if [ ! -f /config/.config/openbox/rc.xml ]; then
  cp /defaults/openbox-rc.xml /config/.config/openbox/rc.xml
fi

# Generate self-signed TLS certificate for port 3001 if absent
CERT_FILE="/config/ssl/cert.pem"
KEY_FILE="/config/ssl/cert.key"
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 3650 \
    -subj "/CN=localhost" \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" >/dev/null 2>&1
  chmod 0600 "$KEY_FILE"
  chmod 0644 "$CERT_FILE"
fi

# Prepare noVNC web root with auto-connecting landing page
mkdir -p /run/firefox-web/www
ln -sfn /usr/share/novnc/* /run/firefox-web/www/ 2>/dev/null || cp -a /usr/share/novnc/. /run/firefox-web/www/
SAFE_TITLE="$(printf '%s' "$TITLE" | sed 's/[&<>"]/ /g')"
cat > /run/firefox-web/www/index.html <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>${SAFE_TITLE}</title>
  <meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&amp;resize=remote&amp;path=websockify">
</head>
<body>
  <p>Connecting to ${SAFE_TITLE}...</p>
</body>
</html>
HTML

# Configure optional HTTP Basic Auth when PASSWORD is provided
AUTH_CONF="/run/firefox-web/auth.conf"
if [ -n "${PASSWORD:-}" ]; then
  AUTH_USER="${CUSTOM_USER:-abc}"
  htpasswd -bcB /run/firefox-web/.htpasswd "$AUTH_USER" "$PASSWORD" >/dev/null 2>&1
  chmod 0640 /run/firefox-web/.htpasswd
  cat > "$AUTH_CONF" <<'CONF'
auth_basic "Restricted";
auth_basic_user_file /run/firefox-web/.htpasswd;
CONF
else
  printf '# Authentication disabled (PASSWORD unset)\n' > "$AUTH_CONF"
fi

cp /defaults/nginx.conf /run/firefox-web/nginx.conf

if [ "$(id -u)" -eq 0 ]; then
  chown abc:abc /config /config/.config /config/.config/openbox /config/.mozilla /config/Desktop /config/Downloads
  chown -R abc:abc /config/ssl /run/firefox-web /var/lib/nginx /var/log/nginx
fi

run_as_abc() {
  if [ "$(id -u)" -eq 0 ]; then
    setpriv --reuid="$PUID" --regid="$PGID" --init-groups env \
      HOME=/config USER=abc DISPLAY="$DISPLAY" \
      XDG_RUNTIME_DIR=/run/firefox-web \
      "$@"
  else
    env HOME=/config DISPLAY="$DISPLAY" XDG_RUNTIME_DIR=/run/firefox-web "$@"
  fi
}

# Clean stale display lock files if container restarted unexpectedly
DISP_NUM="${DISPLAY#:}"
rm -f "/tmp/.X${DISP_NUM}-lock" "/tmp/.X11-unix/X${DISP_NUM}"

# 1. Start TigerVNC X11 server bound strictly to 127.0.0.1:5900
run_as_abc Xtigervnc "$DISPLAY" \
  -geometry "${SCREEN_WIDTH}x${SCREEN_HEIGHT}" \
  -depth "$SCREEN_DEPTH" \
  -rfbport 5900 \
  -localhost \
  -SecurityTypes None \
  -AlwaysShared \
  -AcceptSetDesktopSize=1 &
VNC_PID=$!

# Wait briefly for X11 socket
for _ in $(seq 1 30); do
  if [ -S "/tmp/.X11-unix/X${DISP_NUM}" ]; then
    break
  fi
  sleep 0.25
done

# 2. Start Openbox window manager as non-root abc
run_as_abc openbox --config-file /config/.config/openbox/rc.xml &
WM_PID=$!

# 3. Launch Firefox in a supervised restart loop as non-root abc
(
  while true; do
    if [ -n "${CHROME_CLI:-}" ]; then
      # shellcheck disable=SC2086
      run_as_abc firefox --no-remote $CHROME_CLI || true
    else
      run_as_abc firefox --no-remote || true
    fi
    sleep 2
  done
) &
FF_LOOP_PID=$!

# 4. Start websockify bridge on loopback 127.0.0.1:6080 -> 127.0.0.1:5900 as abc
run_as_abc websockify --web /run/firefox-web/www 127.0.0.1:6080 127.0.0.1:5900 &
WS_PID=$!

# 5. Start NGINX HTTP (:3000) / HTTPS (:3001) reverse proxy
nginx -t -c /run/firefox-web/nginx.conf
nginx -c /run/firefox-web/nginx.conf -g "daemon off;" &
NGINX_PID=$!

shutdown_all() {
  kill -TERM "$FF_LOOP_PID" "$NGINX_PID" "$WS_PID" "$WM_PID" "$VNC_PID" 2>/dev/null || true
  wait "$NGINX_PID" "$WS_PID" "$VNC_PID" 2>/dev/null || true
}
trap shutdown_all TERM INT

wait -n "$VNC_PID" "$WS_PID" "$NGINX_PID"
STATUS=$?
shutdown_all
exit "$STATUS"
