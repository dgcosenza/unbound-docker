# NLnet Labs Unbound for Debian 13 (trixie-slim)

[![Daily Unbound image](https://github.com/dgcosenza/unbound-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/unbound-docker/actions/workflows/daily.yml)
[![Packaging License: MIT](https://img.shields.io/badge/packaging-MIT-blue.svg)](https://github.com/dgcosenza/unbound-docker/blob/main/LICENSE)
[![Upstream License: BSD-3-Clause](https://img.shields.io/badge/upstream-BSD--3--Clause-green.svg)](https://github.com/NLnetLabs/unbound/blob/master/LICENSE)
[![Signed with Cosign](https://img.shields.io/badge/signed-cosign%20OIDC-blueviolet.svg)](#supply-chain-verification)
[![SLSA Level 3](https://img.shields.io/badge/SLSA-Level%203-brightgreen.svg)](#supply-chain-verification)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-informational.svg)](#supported-architectures)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/dgcosenza/unbound-docker/badge)](https://scorecard.dev/viewer/?uri=github.com/dgcosenza/unbound-docker)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/17175/badge)](https://www.bestpractices.dev/projects/17175)
[![Docker Pulls](https://img.shields.io/docker/pulls/dgcosenza/unbound)](https://hub.docker.com/r/dgcosenza/unbound)
[![Docker Image Size](https://img.shields.io/docker/image-size/dgcosenza/unbound/latest)](https://hub.docker.com/r/dgcosenza/unbound)
[![Latest Release](https://img.shields.io/github/v/release/dgcosenza/unbound-docker?label=version)](https://github.com/dgcosenza/unbound-docker/releases)

A source-built, multi-arch, continuously rebuilt **Debian 13 (`trixie-slim`)** container image of [NLnet Labs Unbound](https://nlnetlabs.nl/projects/unbound/about/) and [ldns](https://nlnetlabs.nl/projects/ldns/about/) (`drill`), maintained by **Daniel G. Cosenza from FNX Labs**.

- **Docker Hub:** [`dgcosenza/unbound`](https://hub.docker.com/r/dgcosenza/unbound)
- **GitHub Container Registry (GHCR):** [`ghcr.io/dgcosenza/unbound`](https://github.com/dgcosenza/unbound-docker/pkgs/container/unbound) (identical signed multi-arch digest)
- **Source Repository:** [`dgcosenza/unbound-docker`](https://github.com/dgcosenza/unbound-docker)
- **Upstream Application:** [`NLnetLabs/unbound`](https://github.com/NLnetLabs/unbound) & [`NLnetLabs/ldns`](https://github.com/NLnetLabs/ldns) (`BSD-3-Clause`)

---

## Overview

`dgcosenza/unbound` compiles verified official NLnet Labs Unbound and ldns (`drill`) source tarballs on **Debian 13 (`trixie-slim`)** for both `linux/amd64` and `linux/arm64`, pre-seeded with fresh IANA root hints and an RFC 5011 DNSSEC root trust anchor initialized via `unbound-anchor`:

- **Drop-in replacement for `klutchell/unbound`:** Preserves `/etc/unbound/unbound.conf`, `/etc/unbound/custom.conf.d/*.conf`, `/var/unbound/root.key`, `unbound` (`101:102`) privilege drop, `drill` (and `dig` symlink), and full compiled feature parity (OpenSSL 3, libevent, DNSCrypt, EDNS client subnet, cachedb, nghttp2, TCP Fast Open).
- **Minimal-privilege execution:** Verified under `--cap-drop ALL` with only the minimal capabilities required to bind port `53` and drop privileges to uid `101` under `tini`.
- **Hardened supply chain:** Hadolint + Gitleaks preflight, native multi-arch DNSSEC smoke tests, strict Dive efficiency gate (`>= 95%`, `<= 5%` wasted), Syft SPDX + CycloneDX SBOMs, Trivy + Grype (SBOM) zero-fixable all-severity gates, Cosign keyless OIDC signatures & SBOM attestations, SLSA Build L3 provenance, dual-registry publishing, and signed GitHub Releases.

---

## Current Versions

<!-- versions:start -->
| Component | Resolved Version |
| --- | --- |
| Unbound | `1.26.2` |
| ldns | `1.9.2` |
| Base OS | `Debian 13.8 (trixie-slim)` |
| Architectures | `linux/amd64, linux/arm64` |
| Compressed size (per arch) | `amd64: 35.4 MB, arm64: 35.7 MB` |
| Last verified build (UTC) | `2026-11-26` |
| Published multi-arch digest | `dgcosenza/unbound@sha256:7068e9d881c0857ba4e60421c5fdbc23d962540c97900178287058d18ce235c8` |
| GHCR mirror | `ghcr.io/dgcosenza/unbound@sha256:7068e9d881c0857ba4e60421c5fdbc23d962540c97900178287058d18ce235c8` |
| Supply chain | Cosign OIDC signed + SPDX & CycloneDX SBOM attestations + SLSA Build L3 provenance |
| Security gate (Trivy + Grype on SBOM) | **0 fixable findings of any severity** (17 upstream-unfixed) |

Currently tracked upstream-unfixed findings (no fix released): `CVE-2025-69720`, `CVE-2026-107494`, `CVE-2026-113351`, `CVE-2026-115506`, `CVE-2026-117610`, `CVE-2026-118370`, `CVE-2026-119373`, `CVE-2026-119374`, `CVE-2026-119379`, `CVE-2026-124709` (+7 more in CI artifacts).
<!-- versions:end -->

---

## Supported Tags & Tag Policy

Identical multi-arch OCI digests are published to **Docker Hub** (`dgcosenza/unbound`) and **GHCR** (`ghcr.io/dgcosenza/unbound`), accompanied by an automated signed [GitHub Release](https://github.com/dgcosenza/unbound-docker/releases):

| Tag | Policy | Description |
| --- | --- | --- |
| `<version>-<YYYYMMDD>` (e.g. `1.26.2-20261125`) | **Immutable** | Date-stamped daily rebuild pinning the Unbound release and UTC build date. |
| `sha-<short>` | **Immutable** | Packaging repository Git commit tag. |
| `<version>` (e.g. `1.26.2`) | Moving | Latest verified Debian 13 security rebuild of that Unbound release. |
| `latest` | Moving | Latest verified build tracking the newest official Unbound release. |

**Production pinning:** Pin by immutable digest:

```yaml
image: dgcosenza/unbound:1.26.2@sha256:<digest>
# or via GitHub Container Registry (identical digest):
image: ghcr.io/dgcosenza/unbound:1.26.2@sha256:<digest>
```

---

## Supported Architectures

| Architecture | Status | Verification |
| --- | --- | --- |
| `linux/amd64` | **Published & natively tested** | Compiled from verified tarballs, DNSSEC smoke-tested under minimal capabilities, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native x86_64 CI runners. |
| `linux/arm64` | **Published & natively tested** | Compiled from verified tarballs, DNSSEC smoke-tested under minimal capabilities, Dive-gated, Syft/Trivy/Grype-scanned, and Cosign-signed on native ARM64 CI runners. |

---

## Quick Start

### `docker run` (hardened minimal capabilities)

```bash
docker run -d --name unbound \
  --restart unless-stopped \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  --cap-add SETUID \
  --cap-add SETGID \
  --cap-add CHOWN \
  --cap-add DAC_OVERRIDE \
  --security-opt no-new-privileges:true \
  --tmpfs /tmp:noexec,nosuid,size=16m \
  -p 127.0.0.1:5335:53/tcp \
  -p 127.0.0.1:5335:53/udp \
  dgcosenza/unbound:latest
```

Test recursive DNSSEC validation:

```bash
docker exec unbound drill -D @127.0.0.1 nlnetlabs.nl
```

### Hardened Docker Compose

See [`docker-compose.example.yml`](https://github.com/dgcosenza/unbound-docker/blob/main/docker-compose.example.yml) for a hardened compose example running on an internal bridge network with `cap_drop: [ALL]`, minimal `cap_add`, `no-new-privileges:true`, resource limits, and a `drill` healthcheck.

---

## Configuration

### Ports

| Port | Protocol | Purpose |
| --- | --- | --- |
| `53` | TCP / UDP | Recursive / forwarding DNS resolver |

Keep Unbound on an internal Docker network behind a DNS frontend such as [`dgcosenza/pihole`](https://github.com/dgcosenza/pihole-docker).

### Volumes and Paths

| Path | Mode | Purpose |
| --- | --- | --- |
| `/etc/unbound/unbound.conf` | read-only (optional) | Full custom Unbound configuration replacing built-in defaults |
| `/etc/unbound/custom.conf.d/` | read-only (optional) | Drop-in `*.conf` snippets loaded via `include-toplevel` |
| `/var/unbound/root.key` | writable | RFC 5011 DNSSEC root trust anchor owned by `unbound:unbound` (`101:102`) |
| `/var/unbound/root.hints` | read-only | IANA root server hints refreshed on every daily build |
| `/etc/ssl/certs/ca-certificates.crt` | read-only | Debian CA trust bundle for DNS-over-TLS (`tls-cert-bundle`) |

### Environment Variables & UID/GID

| Variable | Default | Description |
| --- | --- | --- |
| `TZ` | `UTC` | Timezone for log timestamps |

Unbound starts briefly as root solely to bind privileged port `53` and read TLS bundles, then drops privileges to `unbound` (`uid=101`, `gid=102`).

---

## Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["drill", "-Q", "@127.0.0.1", "nlnetlabs.nl"]
```

Both `drill` and a `dig` symlink are shipped in `/usr/bin/`, ensuring compose healthcheck overrides work unmodified.

---

## Upgrading and Migrating from `klutchell/unbound`

1. Back up your mounted `unbound.conf` or `custom.conf.d/` directory.
2. Validate your existing config against the new image:
   ```bash
   docker run --rm -v ./unbound.conf:/etc/unbound/unbound.conf:ro \
     --entrypoint unbound-checkconf dgcosenza/unbound:latest
   ```
3. Replace `klutchell/unbound:latest` with `dgcosenza/unbound:<version>@sha256:<digest>` (or `ghcr.io/dgcosenza/unbound:<version>@sha256:<digest>`).
4. Recreate the container (`docker compose up -d unbound`) and confirm `healthy` status and DNSSEC `ad` flag resolution.

---

## Supply-Chain Verification

Every published digest (multi-arch index and per-architecture manifests) on both Docker Hub and GHCR is keyless-signed with **Sigstore Cosign** (GitHub OIDC), attested with **SPDX** and **CycloneDX** SBOMs, and backed by **SLSA Build L3** provenance (`actions/attest-build-provenance`).

### Verify image signature with Cosign

```bash
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/unbound-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/unbound:latest

# Or against Docker Hub (identical digest):
cosign verify \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/unbound-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  dgcosenza/unbound:latest
```

### Verify SPDX / CycloneDX SBOM attestations

```bash
cosign verify-attestation \
  --type spdxjson \
  --certificate-identity-regexp="^https://github\.com/dgcosenza/unbound-docker/\.github/workflows/daily\.yml@refs/heads/main$" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com" \
  ghcr.io/dgcosenza/unbound@sha256:<arch-digest>
```

### Verify SLSA Build Provenance

```bash
gh attestation verify oci://ghcr.io/dgcosenza/unbound:latest --owner dgcosenza
```

---

## Security

- **Preflight gates:** Every push and PR runs **Hadolint** (blocking on warning+), **Gitleaks** secret scanning across git history, and **public-content/attribution/license** checks.
- **Verified upstream source:** Unbound and ldns tarballs are fetched over HTTPS from NLnet Labs and verified against their official SHA-256 digests prior to compilation.
- **Vulnerability & efficiency gates (all severities with a fix):** Each architecture generates **Syft** SPDX + CycloneDX SBOMs, passes a strict **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted), and must pass **Trivy** (table, JSON, SARIF to Code Scanning, blocking `--ignore-unfixed`) and **Grype** scanning the SPDX SBOM (`--only-fixed --fail-on negligible`) with **0 fixable vulnerabilities of any severity**.
- **Dependency automation:** Renovate (`renovate.json`) pins base image digests and GitHub Action commit SHAs; Dependabot security alerts and OpenSSF Scorecard monitoring are enabled.
- See [`SECURITY.md`](https://github.com/dgcosenza/unbound-docker/blob/main/SECURITY.md) for vulnerability reporting.

---

## Build Locally

```bash
git clone https://github.com/dgcosenza/unbound-docker.git
cd unbound-docker

docker buildx build \
  --platform linux/amd64 \
  --load \
  --build-arg IMAGE_CREATED="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --build-arg IMAGE_REVISION="$(git rev-parse HEAD)" \
  -t dgcosenza/unbound:local \
  .

./tests/smoke.sh dgcosenza/unbound:local
```

| Build Arg | Default | Purpose |
| --- | --- | --- |
| `DEBIAN_BASE` | `debian:trixie-slim@sha256:...` | Digest-pinned Debian 13 base image (refreshed daily by CI) |
| `UNBOUND_VERSION` / `UNBOUND_SHA256` | `1.26.2` / pinned | NLnet Labs Unbound tarball version and SHA-256 |
| `LDNS_VERSION` / `LDNS_SHA256` | `1.9.2` / pinned | NLnet Labs ldns tarball version and SHA-256 |
| `UNBOUND_UID` / `UNBOUND_GID` | `101` / `102` | Unprivileged `unbound` user/group IDs |

---

## Update Policy

[`.github/workflows/daily.yml`](https://github.com/dgcosenza/unbound-docker/blob/main/.github/workflows/daily.yml) runs automatically every day at **05:20 UTC**, on pushes to `main`, on pull requests (verification only), and via `workflow_dispatch`:

1. **Preflight & upstream check:** Runs public-content checks, **Hadolint**, and **Gitleaks**; resolves the latest NLnet Labs Unbound and ldns releases + official SHA-256 digests and latest `debian:trixie-slim` digest; diffs against `versions.json` and emits `upstream-changes.md`.
2. **Multi-arch no-cache rebuild:** Compiles Unbound and ldns natively on `linux/amd64` and `linux/arm64` runners with `--no-cache` on schedule, fresh IANA root hints, fresh DNSSEC root anchor, and full Debian 13 `apt-get upgrade`.
3. **Smoke, Dive & vulnerability gates:** Runs [`tests/smoke.sh`](https://github.com/dgcosenza/unbound-docker/blob/main/tests/smoke.sh) natively on both architectures (minimal capabilities, uid `101` drop, DNSSEC `ad` + bogus `SERVFAIL`), enforces the strict **Dive** efficiency gate (`>= 95%`, `<= 5%` wasted), generates **Syft** SPDX + CycloneDX SBOMs, and gates publication on **0 fixable findings of any severity** in both **Trivy** and **Grype** (SBOM scan).
4. **Dual-registry publish & signing:** Assembles the multi-arch OCI index on **GHCR** (`ghcr.io/dgcosenza/unbound`) and mirrors the identical digest to **Docker Hub** (`dgcosenza/unbound`) with tags `latest`, `<version>`, `<version>-<YYYYMMDD>`, and `sha-<short>`; keyless-signs digests and attaches SPDX/CycloneDX SBOM attestations via **Cosign** OIDC; emits **SLSA Build L3** provenance; and publishes a signed **GitHub Release**.
5. **Automated documentation sync:** Commits updated `versions.json`, the README `Current Versions` block, and a dated `CHANGELOG.md` entry via `github-actions[bot]` (`[skip ci]`), then syncs the Docker Hub overview and short description.
6. **Failure alerting:** Opens or updates a single GitHub issue labeled `ci-failure` on any `main` or scheduled failure, and closes it automatically on the next green run.

---

## Design Decisions

- **Debian 13 (`trixie-slim`) instead of Alpine/scratch copies:** Provides uniform glibc/OpenSSL 3 security updates, standard Debian CA trust management, and complete dpkg metadata for Trivy, Grype, and Syft SBOMs.
- **Two-layer zero-waste runtime layout:** Upgrading Debian 13 inside an `os-base` stage and assembling the final image with cleanly separated OS and compiled-binary layers eliminates overwritten base-layer files so Dive remains at ~100% efficiency and ~0% wasted space across daily security rebuilds.
- **`tini` as PID 1:** Ensures clean signal forwarding and zombie reaping alongside Unbound's own privilege drop.
- **Hadolint `DL3008` ignore:** Daily `--no-cache` security rebuilds intentionally pull the newest Debian 13 security updates via `apt-get` rather than pinning stale package versions.

---

## License

This repository follows a clear packaging-vs-upstream license split:

- **Container packaging, default configuration, CI workflows, scripts, and documentation (`packaging: MIT`):** Licensed under the [MIT License](https://github.com/dgcosenza/unbound-docker/blob/main/LICENSE) — copyright **Daniel G. Cosenza from FNX Labs**.
- **Bundled upstream software — NLnet Labs Unbound & ldns (`upstream: BSD-3-Clause`):** Copyright NLnet Labs and contributors — licensed under the [3-Clause BSD License](https://github.com/NLnetLabs/unbound/blob/master/LICENSE).

Full notices are preserved inside the image (`/usr/share/doc/unbound-notices/`) and in [`THIRD-PARTY-NOTICES.md`](https://github.com/dgcosenza/unbound-docker/blob/main/THIRD-PARTY-NOTICES.md).

---

## Credits

- [NLnet Labs Unbound](https://github.com/NLnetLabs/unbound) and [NLnet Labs ldns](https://nlnetlabs.nl/projects/ldns/about/)
- [klutchell/unbound-docker](https://github.com/klutchell/unbound-docker) — path and feature conventions preserved for drop-in compatibility
- Container packaging, CI, and documentation: maintained by **Daniel G. Cosenza from FNX Labs** ([dgcosenza](https://github.com/dgcosenza))
