# Security Policy

Maintained by **Daniel G. Cosenza from FNX Labs**.

## Supported Versions

Only the latest daily build of `dgcosenza/firefox` installing official Mozilla Firefox packages on Debian 13 (`trixie-slim`) is actively maintained and receives automated security rebuilds.

## Automated Vulnerability Scanning

Every build in GitHub Actions enforces:
- **Trivy** (`--ignore-unfixed`, severity `CRITICAL,HIGH`) blocking gate + table/JSON reports + SARIF upload to GitHub Code Scanning.
- **Grype** (`--only-fixed`, severity cutoff `high`) blocking gate + persisted report artifact.
- **Syft** SPDX SBOM (`sbom.spdx.json`) and build provenance artifacts.

Daily scheduled builds run with `--no-cache`, upgrade all Debian 13 packages, and pull the latest official signed Firefox package from Mozilla's APT repository (`packages.mozilla.org`).

## Reporting a Vulnerability

- **Container packaging or CI issues:** Open a private security advisory via GitHub Security Advisories on [`dgcosenza/firefox-docker`](https://github.com/dgcosenza/firefox-docker/security/advisories/new).
- **Upstream Mozilla Firefox issues:** Report via Mozilla's security program at [mozilla.org/en-US/security](https://www.mozilla.org/en-US/security/).
