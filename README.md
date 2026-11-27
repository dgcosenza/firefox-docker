# Firefox Web Desktop — Debian 13 (trixie-slim) Image

[![Daily Firefox image](https://github.com/dgcosenza/firefox-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/firefox-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/firefox-docker/blob/main/LICENSE)
[![Upstream License: MPL-2.0](https://img.shields.io/badge/upstream-MPL--2.0-green.svg)](https://www.mozilla.org/en-US/MPL/2.0/)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/firefox-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/firefox-docker)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/17157/badge)](https://www.bestpractices.dev/projects/17157)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/firefox)](https://hub.docker.com/r/dgcosenza/firefox)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/firefox/latest)](https://hub.docker.com/r/dgcosenza/firefox)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/firefox-docker?label=version)](https://github.com/dgcosenza/firefox-docker/releases)

A lean, hardened **Mozilla Firefox** web desktop container on **Debian 13 (`trixie-slim`)** backed by official Mozilla APT packages, **TigerVNC**, **noVNC**, **Openbox**, and an **HTTPS NGINX** front end, maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/firefox`](https://hub.docker.com/r/dgcosenza/firefox)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/firefox`](https://github.com/dgcosenza/firefox-docker/pkgs/container/firefox) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/firefox-docker`](https://github.com/dgcosenza/firefox-docker)
- **Upstream Application:** Official [Mozilla Firefox](https://www.mozilla.org/firefox/) Debian APT repository (`packages.mozilla.org`, MPL-2.0)
- **Packaging License:** MIT (see [`LICENSE`](https://github.com/dgcosenza/firefox-docker/blob/main/LICENSE) and [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/firefox-docker/blob/main/THIRD-PARTY-NOTICES.md))

---

## Overview

`dgcosenza/firefox` runs the latest official **Mozilla Firefox** release (verified against Mozilla's APT GPG signing key) inside a minimal **Debian 13 (`trixie-slim`)** web desktop:

- **Zero Docker-in-Docker bloat:** Omits embedded Docker/containerd daemons, Node.js runtimes, and custom binary blobs, eliminating unnecessary attack surface and Go/npm CVEs.
- **Drop-in `/config` profile compatibility:** Preserves `HOME=/config`, `/config/.mozilla`, `/config/Desktop`, `/config/Downloads`, `/config/ssl/cert.{pem,key}`, `PUID`/`PGID` (user `abc`), `CUSTOM_USER`/`PASSWORD` HTTP Basic Auth, `CHROME_CLI`, `TITLE`, `/dev/dri` Mesa VAAPI/GL support, HTTP `:3000`, and HTTPS `:3001`.
- **Hardened & CVE-gated (all severities with a fix):** Runs with `tini` as PID 1, drops desktop/browser processes (`Xtigervnc`, `openbox`, `firefox`, `websockify`, NGINX workers) to non-root `abc` via `setpriv` (fully compatible with `security_opt: no-new-privileges:true`), binds VNC strictly to `127.0.0.1:5900`, and gates every build on **0 fixable findings of any severity** in both Trivy and Grype.

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| Mozilla Firefox | `161.0` |
| Web Desktop | `TigerVNC + noVNC + Openbox` |
| Base OS | `Debian 13.8 (trixie-slim)` |
| Architectures | `linux/amd64, linux/arm64` |
| Uncompressed size (per arch) | `amd64: 369.9 MB, arm64: 997.4 MB` |
| Last verified build (UTC) | `2026-11-27` |
| Published multi-arch digest | `dgcosenza/firefox@sha256:7c1516e0b00b309d1eaf229c381974b1306958197af6cb5f2c2ece940b8df1a4` |
| GHCR mirror | `ghcr.io/dgcosenza/firefox@sha256:7c1516e0b00b309d1eaf229c381974b1306958197af6cb5f2c2ece940b8df1a4` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable findings of any severity** (46 upstream-unfixed) |
<!-- versions:end -->

---

## Supported Tags

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<YYYYMMDD>` (e.g. `161.0-20261124`) | **Immutable** | Date-stamped daily rebuild pinning the Firefox release and UTC build date. |
| `sha-<short>` | **Immutable** | Packaging repository Git commit tag. |
| `<version>` (e.g. `161.0`) | Moving | Latest verified Debian 13 rebuild of that Firefox release. |
| `latest` | Moving | Latest verified build tracking the newest official Mozilla Firefox release. |

**Production pinning:** Pin by registry digest:

```yaml
image: dgcosenza/firefox:latest@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Built, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Built, smoke-tested, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

Identical multi-arch OCI manifest digests are published to **Docker Hub** and **GHCR** (`ghcr.io/dgcosenza/*`), accompanied by automated signed [GitHub Releases](https://github.com/dgcosenza/firefox-docker/releases).
---

## Quick Start

### `docker run`

```bash
docker run -d \
  --name firefox \
  --restart unless-stopped \
  --security-opt no-new-privileges:true \
  --security-opt seccomp:unconfined \
  --shm-size 1g \
  -p 192.0.2.10:3001:3001 \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Etc/UTC \
  -e CUSTOM_USER=browser \
  -e PASSWORD="replace-with-a-strong-password" \
  -e CHROME_CLI="https://start.duckduckgo.com/" \
  -v "$(pwd)/config:/config" \
  dgcosenza/firefox:latest
```

### Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/firefox-docker/blob/main/docker-compose.example.yml).

---

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
| --- | --- | --- | --- |
| `PUID` | No | `1000` | UID assigned to the non-root `abc` desktop user. |
| `PGID` | No | `1000` | GID assigned to the non-root `abc` desktop group. |
| `TZ` | No | `Etc/UTC` | Container timezone (IANA timezone name). |
| `CUSTOM_USER` | No | `abc` | HTTP Basic Auth username when `PASSWORD` is set. |
| `PASSWORD` | Recommended | *(unset)* | Enables HTTP Basic Auth (bcrypt) on ports `3000` and `3001` when non-empty. |
| `TITLE` | No | `Firefox` | HTML page title for the noVNC web client. |
| `CHROME_CLI` | No | *(unset)* | Optional URL or CLI arguments passed to `firefox --no-remote`. |
| `SCREEN_WIDTH` / `SCREEN_HEIGHT` / `SCREEN_DEPTH` | No | `1440` / `900` / `24` | Initial virtual display geometry (noVNC dynamically resizes to fit the browser viewport). |
| `MOZ_USE_XINPUT2` | No | `1` | Enables XInput2 smooth scrolling and touch input in Firefox. |
| `MOZ_WEBRENDER_DISABLED` | No | *(unset)* | Set to `1` to force software rendering if GPU compositing is undesirable. |

### Volumes, Ports, and UID/GID

| Path / Port | Mode / Owner | Purpose |
| --- | --- | --- |
| `/config` | `PUID:PGID` (`abc`) | Persistent `HOME`: `.mozilla/` profile, `Downloads/`, `Desktop/`, `.config/openbox/`, `ssl/cert.{pem,key}`. |
| `/dev/dri` *(optional)* | Host GPU nodes | Optional bind mount for Mesa DRI/VAAPI acceleration (add host `video` and `render` GIDs via `group_add`). |
| `3000/tcp` | HTTP | noVNC web interface (prefer reverse proxy or `3001/tcp`). |
| `3001/tcp` | HTTPS | TLS-encrypted noVNC web interface (probed by the built-in healthcheck). |

---

## Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD ["sh", "-c", "curl -sk -o /dev/null -w '%{http_code}' --max-time 5 https://127.0.0.1:3001/ | grep -qE '^(200|301|302|401)$'"]
```

Verifies the local HTTPS reverse proxy on port `3001` responds with HTTP `200`, `301`, `302`, or `401` (when Basic Auth is enabled).

---

## Upgrading and Migrating from `lscr.io/linuxserver/firefox`

1. Back up `./config` (especially `./config/.mozilla`) and tag the outgoing image for rollback.
2. Keep your existing `./config:/config`, `/dev/dri:/dev/dri`, `shm_size: "1g"`, `PUID`/`PGID`, `CUSTOM_USER`, `PASSWORD`, and `CHROME_CLI` settings.
3. Test side-by-side against a copy of `./config` on non-conflicting loopback ports, verify Basic Auth and profile bookmarks/extensions load cleanly, then pin `image: dgcosenza/firefox:latest@sha256:<digest>` and recreate the container.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/firefox-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/firefox:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/firefox-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/firefox:latest
```

### Verify SPDX / CycloneDX SBOM attestations and SLSA Build Provenance

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/firefox-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/firefox@sha256:<arch-digest>

gh attestation verify oci://ghcr.io/dgcosenza/firefox:latest --owner dgcosenza
```

---

## Security

- **Vulnerability scan policy (all severities with a fix):** Every CI build runs **Trivy** (table, JSON, SARIF upload, blocking `--ignore-unfixed` gate) and **Grype** (`--only-fixed`, severity cutoff `negligible`, blocking gate), plus emits an **SPDX SBOM** (`sbom.spdx.json`) and provenance artifact.
- **Current status:** **0 fixable vulnerabilities of any severity** across Debian 13 OS packages and official Mozilla Firefox.
- **Process isolation:** `Xtigervnc` listens strictly on `127.0.0.1:5900` (never exposed directly); external clients connect over TLS on `:3001` behind bcrypt HTTP Basic Auth. Desktop processes run as non-root `abc` via `setpriv` without requiring `sudo` or disabling `no-new-privileges:true`.
- See [`SECURITY.md`](https://github.com/dgcosenza/firefox-docker/blob/main/SECURITY.md).

---

## Build Locally

```bash
git clone https://github.com/dgcosenza/firefox-docker.git
cd firefox-docker

docker buildx build \
  --platform linux/amd64 \
  --load \
  --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg IMAGE_REVISION="$(git rev-parse HEAD)" \
  -t dgcosenza/firefox:local \
  .
```

| Build Arg | Default | Purpose |
| --- | --- | --- |
| `FIREFOX_VERSION` | `161.0~build1` | Official Mozilla Debian APT package version (resolved daily by CI). |
| `DEBIAN_BASE` | `debian:trixie-slim` | Base OS image. |
| `BUILD_DATE` | `unknown` | RFC 3339 UTC build timestamp. |
| `IMAGE_REVISION` | `""` | Packaging repository Git SHA. |
| `IMAGE_SOURCE` | `https://github.com/dgcosenza/firefox-docker` | Source URL for OCI labels. |

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/firefox-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **04:39 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`. Every scheduled run executes a seven-step automated pipeline (gated by `.github/workflows/public-check.yml`):

1. **Upstream check:** Queries Mozilla's official Debian APT feed (`packages.mozilla.org`) for the latest stable Firefox package and resolves the `debian:trixie-slim` digest, diffs against `versions.json`, and emits `upstream-changes.md`.
2. **No-cache rebuild:** Rebuilds `linux/amd64` with `--no-cache` on schedule, upgrades all Debian 13 packages (`apt-get update && apt-get -y upgrade`), verifies Mozilla's APT GPG fingerprint, installs latest Firefox, and generates an **SPDX SBOM** (`sbom.spdx.json`) and provenance artifact.
3. **Vulnerability fix and gate:** Runs **Trivy** (table, JSON, SARIF upload, blocking `--ignore-unfixed` gate) and **Grype** (blocking `--only-fixed` gate, severity cutoff `negligible`), diffs findings against the previous scan, and retains reports for 90 days.
4. **Smoke test:** Executes [`tests/smoke.sh`](https://github.com/dgcosenza/firefox-docker/blob/main/tests/smoke.sh) to verify Firefox version, `tini` PID 1, non-root `abc` desktop processes, Basic Auth enforcement on `:3001` (401 unauthenticated, 200 authenticated), and a negative closed-port healthcheck test.
5. **Publish:** On non-PR builds when Docker Hub secrets are configured, pushes `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>` tags to Docker Hub and records the immutable digest.
6. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` with `[skip ci]` when content changes, then syncs the Docker Hub overview via `peter-evans/dockerhub-description`.
7. **Failure alerting:** On failure, CI opens or updates a single GitHub issue labeled `ci-failure` with the failing job and run link, and auto-closes it on the next green run.

---

## Design Decisions

- **Official Mozilla APT repo on Debian 13 (`trixie-slim`):** Ships current mainstream Mozilla Firefox releases (not Debian ESR) signed with Mozilla's official key while keeping the base OS tracked by Debian 13 Security.
- **TigerVNC + noVNC + NGINX instead of bundled Docker-in-Docker:** Keeps the entire remote-desktop stack in official Debian 13 packages, eliminating hundreds of megabytes of third-party wheels and Docker-in-Docker Go binaries that introduce avoidable CVEs.
- **`setpriv` instead of `sudo`:** Drops desktop processes to UID/GID `PUID:PGID` while staying 100% compatible with `security_opt: no-new-privileges:true`.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, scripts, CI workflows, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/firefox-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — Mozilla Firefox (`packages.mozilla.org`) (`upstream: MPL-2.0`):** Mozilla Firefox is distributed by the Mozilla Foundation under the [Mozilla Public License 2.0 (`MPL-2.0`)](https://www.mozilla.org/en-US/MPL/2.0/).

Full third-party notices are maintained in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/firefox-docker/blob/main/THIRD-PARTY-NOTICES.md). Release history is maintained in [`CHANGELOG.md`](https://github.com/dgcosenza/firefox-docker/blob/main/CHANGELOG.md).
