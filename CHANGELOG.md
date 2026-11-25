# Changelog

All notable changes to the `dgcosenza/firefox` Debian 13 container packaging and CI workflows are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Maintained by **Daniel G. Cosenza from FNX Labs**.

---
<!-- changelog:auto -->

## [161.0] — 2026-11-24

### Added
- Initial **Debian 13 (`trixie-slim`)** web-accessible **Mozilla Firefox** image using Mozilla's GPG-verified Debian APT repository (`packages.mozilla.org`), TigerVNC, noVNC, Openbox, and HTTPS NGINX reverse proxy on ports `3000`/`3001`.
- Drop-in `/config` profile support (`PUID`/`PGID` user `abc`, `CUSTOM_USER`/`PASSWORD` Basic Auth, `CHROME_CLI`, `TITLE`, `/dev/dri`), `tini` PID 1, `no-new-privileges:true` compatibility via `setpriv`, and zero Docker-in-Docker bloat.
- Seven-step automated daily CI pipeline (`.github/workflows/daily.yml`) with Trivy and Grype fixable Critical/High blocking gates, Syft SPDX SBOM, smoke test (`tests/smoke.sh`), automated docs/Hub sync, and `ci-failure` issue alerting.
