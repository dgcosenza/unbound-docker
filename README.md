# NLnet Labs Unbound for Debian 13 (trixie)

[![Daily build, scan and publish](https://github.com/dgcosenza/unbound-docker/actions/workflows/daily.yml/badge.svg)](https://github.com/dgcosenza/unbound-docker/actions/workflows/daily.yml)
[![Docker Hub pulls](https://img.shields.io/docker/pulls/dgcosenza/unbound.svg)](https://hub.docker.com/r/dgcosenza/unbound)
[![Image size](https://img.shields.io/docker/image-size/dgcosenza/unbound/latest.svg)](https://hub.docker.com/r/dgcosenza/unbound)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A hardened, continuously rebuilt **Debian 13 (trixie)** container image of
[NLnet Labs Unbound](https://nlnetlabs.nl/projects/unbound/about/), compiled
from official verified source tarballs together with NLnet Labs
[ldns](https://nlnetlabs.nl/projects/ldns/about/) (`drill`), IANA root hints,
and an RFC 5011 DNSSEC root trust anchor initialized via `unbound-anchor`.

It is a **drop-in replacement** for `klutchell/unbound`: same configuration
paths (`/etc/unbound/unbound.conf` and `/etc/unbound/custom.conf.d/*.conf`),
same DNSSEC anchor location (`/var/unbound/root.key`), same unprivileged
service account (`unbound`, uid `101`, gid `102`), same `drill` healthcheck
binary, and full compiled-in feature parity (OpenSSL 3, libevent, DNSCrypt,
EDNS client subnet, cachedb, nghttp2, TCP Fast Open).

## Current versions

<!-- versions:start -->

| Component | Resolved version |
|---|---|
| Base OS | Debian `13` (`debian:trixie-slim`) |
| `unbound` | `1.26.2` |
| `ldns` | `1.9.2` |
| Last verified build | `2026-11-24` |
| Fixable CRITICAL / HIGH CVEs | `0` (Trivy + Grype gate) |

<!-- versions:end -->

## Supported tags

| Tag | Meaning |
|---|---|
| `latest` | Newest successfully built, tested, and scanned image |
| `<unbound-version>` | Upstream Unbound release, e.g. `1.26.2` (moves on daily rebuilds of that release) |
| `<unbound-version>-<YYYYMMDD>` | Immutable date-stamped build of that release |
| `sha-<short>` | Immutable build of a specific repository commit |

Pin production deployments by digest:

```bash
docker pull dgcosenza/unbound:latest
docker inspect --format='{{index .RepoDigests 0}}' dgcosenza/unbound:latest
# image: dgcosenza/unbound@sha256:...
```

## Quick start

```bash
docker run -d --name unbound \
  --restart unless-stopped \
  --security-opt no-new-privileges:true \
  -p 127.0.0.1:5335:53/tcp \
  -p 127.0.0.1:5335:53/udp \
  dgcosenza/unbound:latest
```

Test recursive DNSSEC resolution:

```bash
docker exec unbound drill -D @127.0.0.1 nlnetlabs.nl
```

## Compose example

See [docker-compose.example.yml](docker-compose.example.yml) for a complete
compose definition running Unbound on an internal bridge network with memory
limits, `no-new-privileges:true`, and a `drill` healthcheck.

## Configuration

### Ports

| Port | Protocol | Purpose |
|---|---|---|
| `53` | TCP / UDP | DNS recursive / forwarding resolver |

Keep Unbound on a private internal bridge network behind a DNS frontend such as
[dgcosenza/pihole](https://github.com/dgcosenza/pihole-docker), rather than
exposing port `53` directly to untrusted networks.

### Volumes and paths

| Path | Mode | Purpose |
|---|---|---|
| `/etc/unbound/unbound.conf` | read-only (optional) | Full custom Unbound configuration replacing the built-in defaults |
| `/etc/unbound/custom.conf.d/` | read-only (optional) | Drop-in `*.conf` snippets loaded via `include-toplevel` |
| `/var/unbound/root.key` | writable (in container) | RFC 5011 DNSSEC root trust anchor initialized at build time and owned by `unbound:unbound` |
| `/var/unbound/root.hints` | read-only | IANA root server hints refreshed on every daily build |
| `/etc/ssl/certs/ca-certificates.crt` | read-only | Debian CA trust store for DNS-over-TLS (`tls-cert-bundle`) |

### Environment variables

Unbound is configured purely via `/etc/unbound/unbound.conf` and
`/etc/unbound/custom.conf.d/*.conf`. Standard container variables are supported:

| Variable | Default | Description |
|---|---|---|
| `TZ` | `UTC` | Timezone for log timestamps |

### Extending access control for local networks

The default `/etc/unbound/unbound.conf` allows loopback (`127.0.0.0/8`, `::1/128`)
and Docker bridge subnets (`172.16.0.0/12`, `fd00::/8`). To permit additional
private ranges (for example, `192.0.2.0/24`), add a drop-in file under
`/etc/unbound/custom.conf.d/lan.conf`:

```text
server:
    access-control: 192.0.2.0/24 allow
```

### UID / GID

Unbound starts as root only long enough to bind privileged port `53` and read
TLS certificates, then drops privileges to the unprivileged `unbound` service
account (`uid=101`, `gid=102`), matching `klutchell/unbound`.

## Healthcheck

```text
drill -Q @127.0.0.1 nlnetlabs.nl
```

The built-in healthcheck runs every 30 s (10 s timeout, 30 s start period, 3
retries). Both `drill` and a `dig` symlink are shipped in `/usr/bin/`, so
compose overrides calling `drill -Q @127.0.0.1 <domain>` work unmodified.

## Upgrading and migrating from `klutchell/unbound`

1. Back up your mounted `unbound.conf` or `custom.conf.d/` directory.
2. Replace `klutchell/unbound:latest` in your compose file with
   `dgcosenza/unbound:<version>@sha256:<digest>`.
3. Verify your existing configuration against the new image before swapping:
   ```bash
   docker run --rm -v ./unbound.conf:/etc/unbound/unbound.conf:ro \
     --entrypoint unbound-checkconf dgcosenza/unbound:latest
   ```
4. Recreate the container (`docker compose up -d unbound`) and verify DNSSEC
   resolution with `docker exec unbound drill -D @127.0.0.1 nlnetlabs.nl`.

Rollback is immediate: restore the previous image reference in your compose
file and run `docker compose up -d unbound`.

## Security

* **Base OS:** `debian:trixie-slim`, fully upgraded (`apt-get upgrade`) on
  every build with `--no-install-recommends` and cleaned APT lists.
* **Verified upstream sources:** Unbound and ldns tarballs are fetched directly
  from NLnet Labs over HTTPS and checked against their official SHA-256 digests
  before compiling.
* **DNSSEC by default:** `root.hints` and `root.key` are initialized at build
  time via `unbound-anchor` with RFC 5011 automated tracking enabled.
* **Privilege drop & PID 1:** `tini` handles signal forwarding and zombie
  reaping as PID 1; Unbound drops privileges to `unbound` (`101:102`) after
  binding port 53 and supports `no-new-privileges:true`.
* **Scan policy:** every build must pass **Trivy** (`--ignore-unfixed`,
  `CRITICAL,HIGH`) and **Grype** (`--only-fixed`, severity `high`) with **0
  fixable CRITICAL or HIGH** vulnerabilities. Full scan reports and a Syft SPDX
  SBOM are archived for 90 days; Trivy SARIF is uploaded to GitHub code
  scanning.
* **Current status:** see the CI badge above and the "Current versions" table.
  Any unfixed upstream findings with no available patch are automatically listed
  in "Current versions".

## Building locally

```bash
git clone https://github.com/dgcosenza/unbound-docker.git
cd unbound-docker
docker build -t dgcosenza/unbound:dev .
./tests/smoke.sh dgcosenza/unbound:dev
```

Build arguments (all have documented defaults in `Dockerfile`):

| Argument | Default | Purpose |
|---|---|---|
| `DEBIAN_VERSION` | `trixie-slim` | Debian 13 base tag |
| `UNBOUND_VERSION` / `UNBOUND_SHA256` | tracked release | NLnet Labs Unbound tarball version and SHA-256 |
| `LDNS_VERSION` / `LDNS_SHA256` | tracked release | NLnet Labs ldns tarball version and SHA-256 |
| `UNBOUND_UID` / `UNBOUND_GID` | `101` / `102` | Unprivileged `unbound` user/group IDs |
| `IMAGE_CREATED`, `IMAGE_REVISION`, `IMAGE_SOURCE` | empty / repo | OCI image metadata |

## Update policy

A GitHub Actions workflow (`.github/workflows/daily.yml`) runs **daily** (and on
every push to `main`, on pull requests, and on demand via `workflow_dispatch`),
gated first by `.github/workflows/public-check.yml`:

1. **Upstream check:** resolves the latest NLnet Labs Unbound release via the
   authenticated GitHub API (`GH_TOKEN`), fetches official SHA-256 digests for
   Unbound and ldns, diffs against `versions.json`, and captures upstream
   release notes for newly published versions.
2. **Clean rebuild:** rebuilds `linux/amd64` from `debian:trixie-slim` with
   `apt-get upgrade`, fresh IANA root hints, a fresh DNSSEC root anchor, and
   `--no-cache` on scheduled runs.
3. **Vulnerability fix and gate:** scans the candidate image with **Trivy**
   (table, JSON, SARIF to GitHub code scanning) and **Grype**; fails on any
   fixable **CRITICAL** or **HIGH** vulnerability, archives reports and an SPDX
   SBOM (Syft) for 90 days, and diffs findings against the prior build.
4. **Smoke test:** starts the container, waits for `healthy`, verifies privilege
   drop to uid `101`, confirms recursive resolution and DNSSEC validation
   (including `SERVFAIL` for bogus signatures), and verifies negative failure
   cases.
5. **Publish:** on non-PR runs with Docker Hub credentials configured, pushes
   `latest`, `<version>`, `<version>-<YYYYMMDD>` (immutable), and `sha-<short>`,
   recording the published digest.
6. **Automated documentation sync:** when versions, base OS, digest, or CVE
   status change, commits updated `versions.json`, the README "Current
   versions" block, and a dated `CHANGELOG.md` entry (`[skip ci]`), then syncs
   the README and short description to Docker Hub.
7. **Alerting:** on failure of any job on a scheduled or `main` run, opens or
   updates a single GitHub issue labeled `ci-failure` with the failing job and
   run link, and closes it automatically on the next green run.

## Design decisions

* **Debian 13 slim instead of Alpine/scratch.** `klutchell/unbound` copies
  musl-linked Alpine libraries into `scratch`. Building on `debian:trixie-slim`
  gives uniform glibc/OpenSSL 3 security updates via `apt-get upgrade`, full
  Debian CA bundle management, clean scanner visibility (dpkg metadata in Trivy,
  Grype, and Syft SBOMs), and consistent troubleshooting across containers.
* **Compiled from official NLnet Labs source.** Compiling Unbound and ldns
  directly from official verified tarballs delivers the newest upstream
  releases and exact compile-time features (`dnscrypt`, `subnet`, `cachedb`,
  `tfo`, `libevent`, `nghttp2`) without waiting for distro backports.
* **`tini` as PID 1.** Provides clean `SIGTERM`/`SIGINT`/`SIGHUP` forwarding
  and zombie reaping without interfering with Unbound's own privilege drop or
  CLI arguments.
* **Bounded default cache sizes.** Default `msg-cache-size: 48m` and
  `rrset-cache-size: 96m` prevent unbounded memory growth inside memory-limited
  containers.

## License

The packaging, scripts, workflow, and documentation in this repository are
licensed under the **MIT License** (see [LICENSE](LICENSE)). NLnet Labs Unbound
and ldns are licensed under the **3-Clause BSD License** (see
[THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md)).

## Credits

* [NLnet Labs Unbound](https://github.com/NLnetLabs/unbound) — validating,
  recursive, caching DNS resolver
* [NLnet Labs ldns](https://nlnetlabs.nl/projects/ldns/about/) — DNS library
  and `drill` tool
* [klutchell/unbound-docker](https://github.com/klutchell/unbound-docker) —
  path and feature conventions preserved for drop-in compatibility
* Container packaging, CI, and documentation: maintained by Daniel G. Cosenza from FNX Labs ([dgcosenza](https://github.com/dgcosenza))
