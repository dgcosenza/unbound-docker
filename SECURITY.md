# Security policy

Maintainer: Daniel G. Cosenza from FNX Labs.

## Supported versions

Only the `latest` tag and the newest `<unbound-version>` tag are supported. The
image is rebuilt daily from `debian:trixie-slim` with a full `apt-get upgrade`
and freshly compiled upstream source when a new release is published.

## Reporting a vulnerability

Open a private security advisory at
<https://github.com/dgcosenza/unbound-docker/security/advisories/new>. Please do
not open a public issue for an undisclosed vulnerability.

## What this repository covers

This repository owns the packaging layer: the Dockerfile, default configuration,
smoke tests, CI pipeline, and published container tags. Vulnerabilities in
Unbound or ldns itself should also be reported upstream to NLnet Labs via
<https://nlnetlabs.nl/security/>.

## Scanning and gates

* **Trivy:** the build fails on any fixable **CRITICAL** or **HIGH** finding
  across OS packages and libraries. Full reports are attached as 90-day
  artifacts and SARIF results are uploaded to GitHub code scanning.
* **Grype:** runs as a blocking gate (`--only-fixed`, severity high/critical),
  with reports archived for 90 days.
* **SBOM:** an SPDX JSON software bill of materials is generated with Syft and
  archived for 90 days.
* **Privilege drop:** Unbound binds port 53 and drops privileges to the
  unprivileged `unbound` user (uid 101, gid 102). `no-new-privileges:true` is
  supported and recommended.

## Hardening recommendations

* Pin production deployments by `@sha256:<digest>`.
* Run with `security_opt: [no-new-privileges:true]`.
* Keep Unbound on an internal bridge network reachable only by your local DNS
  frontend (such as Pi-hole), without publishing port 53 to the public internet.
* Mount custom configuration read-only at `/etc/unbound/unbound.conf:ro` or
  under `/etc/unbound/custom.conf.d/`.
