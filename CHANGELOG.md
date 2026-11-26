# Changelog

All notable changes to the `dgcosenza/firefox` Debian 13 container packaging and CI workflows are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Maintained by **Daniel G. Cosenza from FNX Labs**.

---
<!-- changelog:auto -->

## [161.0] — 2026-11-26

### Automated Daily Build
- Verified components: Mozilla Firefox `161.0`, Web Desktop `TigerVNC + noVNC + Openbox`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream status: no new upstream release since previous build; refreshed base OS and dependencies.
- Vulnerability gate: **0 fixable findings of any severity** in Trivy and Grype (SBOM scan) (46 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/firefox@sha256:fb94d3047252678bc84ecc26c4bb118f51fc4e2a69d8daf6e1ab768f25b9b8c5` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

## [161.0] — 2026-11-25

### Automated Daily Build
- Verified components: Mozilla Firefox `161.0`, Web Desktop `TigerVNC + noVNC + Openbox`, Base OS `Debian 13.8 (trixie-slim)`.
- Architectures verified: `linux/amd64, linux/arm64` (native smoke tests + Dive efficiency gate).
- Upstream status: no new upstream release since previous build; refreshed base OS and dependencies.
- Vulnerability gate: **0 fixable Critical/High** in Trivy and Grype (SBOM scan) (46 upstream-unfixed).
- Published multi-arch digest (Docker Hub + GHCR): `dgcosenza/firefox@sha256:db728cced62c34c062fc53265ebb892f7c4cf9dbbec8c094664e8d94c3f99dfe` (Cosign OIDC signed + SPDX/CycloneDX SBOM + SLSA L3 provenance).
---

## [161.0] — 2026-11-24

### Added
- Initial **Debian 13 (`trixie-slim`)** web-accessible **Mozilla Firefox** image using Mozilla's GPG-verified Debian APT repository (`packages.mozilla.org`), TigerVNC, noVNC, Openbox, and HTTPS NGINX reverse proxy on ports `3000`/`3001`.
- Drop-in `/config` profile support (`PUID`/`PGID` user `abc`, `CUSTOM_USER`/`PASSWORD` Basic Auth, `CHROME_CLI`, `TITLE`, `/dev/dri`), `tini` PID 1, `no-new-privileges:true` compatibility via `setpriv`, and zero Docker-in-Docker bloat.
- Seven-step automated daily CI pipeline (`.github/workflows/daily.yml`) with Trivy and Grype fixable Critical/High blocking gates, Syft SPDX SBOM, smoke test (`tests/smoke.sh`), automated docs/Hub sync, and `ci-failure` issue alerting.
