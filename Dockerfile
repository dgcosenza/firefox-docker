# syntax=docker/dockerfile:1.7

ARG DEBIAN_BASE=debian:trixie-slim
ARG FIREFOX_VERSION=161.0~build1

FROM ${DEBIAN_BASE} AS runtime

ARG FIREFOX_VERSION
ARG BUILD_DATE=unknown
ARG IMAGE_REVISION=""
ARG IMAGE_SOURCE="https://github.com/dgcosenza/firefox-docker"
ARG DEBIAN_FRONTEND=noninteractive

# Upgrade Debian 13 (trixie-slim) base and install prerequisites for Mozilla APT repo
RUN apt-get update \
    && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
       apache2-utils ca-certificates curl dbus-x11 fonts-noto-color-emoji \
       fonts-noto-core gpg libegl1 libgl1-mesa-dri mesa-va-drivers \
       nginx-light novnc openbox openssl passwd procps tigervnc-standalone-server \
       tini tzdata util-linux websockify xclip xdg-utils \
    && rm -rf /var/lib/apt/lists/*

# Configure Mozilla's official signed Debian APT repository and verify key fingerprint
RUN set -eux; \
    install -d -m 0755 /etc/apt/keyrings; \
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
      -o /etc/apt/keyrings/packages.mozilla.org.asc; \
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc \
      | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") found=1} END{exit !found}'; \
    printf 'Types: deb\nURIs: https://packages.mozilla.org/apt\nSuites: mozilla\nComponents: main\nSigned-By: /etc/apt/keyrings/packages.mozilla.org.asc\n' \
      > /etc/apt/sources.list.d/mozilla.sources; \
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' \
      > /etc/apt/preferences.d/mozilla; \
    apt-get update; \
    apt-get install -y --no-install-recommends "firefox=${FIREFOX_VERSION}" || apt-get install -y --no-install-recommends firefox; \
    apt-get purge -y --auto-remove gpg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Apply quiet first-run defaults for container usage
RUN set -eux; \
    mkdir -p /usr/lib/firefox/distribution /usr/lib/firefox/browser/defaults/preferences; \
    printf '%s\n' \
      'pref("datareporting.policy.firstRunURL", "");' \
      'pref("datareporting.policy.dataSubmissionEnabled", false);' \
      'pref("datareporting.healthreport.uploadEnabled", false);' \
      'pref("browser.aboutwelcome.enabled", false);' \
      'pref("browser.shell.checkDefaultBrowser", false);' \
      'pref("security.sandbox.warn_unprivileged_namespaces", false);' \
      > /usr/lib/firefox/browser/defaults/preferences/container-defaults.js

# Create default abc user/group (UID/GID 1000, reconciled via PUID/PGID at boot)
RUN groupadd --gid 1000 abc \
    && useradd --uid 1000 --gid 1000 --create-home --home-dir /config \
       --shell /bin/bash --comment 'Firefox desktop user' abc \
    && mkdir -p /defaults /config /run/firefox-web /var/log/nginx /var/lib/nginx \
    && chown -R abc:abc /config /run/firefox-web /var/log/nginx /var/lib/nginx

COPY defaults/ /defaults/
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

ENV PUID=1000 \
    PGID=1000 \
    TZ=Etc/UTC \
    HOME=/config \
    DISPLAY=:1 \
    TITLE=Firefox \
    SCREEN_WIDTH=1440 \
    SCREEN_HEIGHT=900 \
    SCREEN_DEPTH=24 \
    MOZ_USE_XINPUT2=1

EXPOSE 3000 3001
VOLUME ["/config"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["sh", "-c", "curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:3001/ | grep -qE '^(200|301|302|401)$'"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/docker-entrypoint.sh"]

LABEL org.opencontainers.image.title="Firefox Web Desktop (Debian 13)" \
      org.opencontainers.image.description="Hardened Debian 13 (trixie-slim) web-accessible Firefox desktop using official Mozilla packages, TigerVNC, noVNC, and HTTPS NGINX proxy, maintained by Daniel G. Cosenza from FNX Labs." \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/firefox" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.version="${FIREFOX_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      io.github.dgcosenza.firefox.upstream_version="${FIREFOX_VERSION}"
