# Changelog

Maintained by Daniel G. Cosenza from FNX Labs.

All notable changes to this image are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and image tags track
the upstream NLnet Labs Unbound release version.

## [1.26.2] - 2026-11-25

### Changed

- Rebuilt on Debian `13.8` (`debian:trixie-slim`) with unbound `1.26.2`, ldns `1.9.2`.
- Verified `0` fixable CRITICAL/HIGH vulnerabilities in Trivy and Grype.
- Published digest: `dgcosenza/unbound@sha256:7e7186b9907298a8646775de478910730112ea5affc252ed39eeac45f99624b2`.
## [1.26.2] - 2026-11-24

### Added

- Initial public build: NLnet Labs Unbound `1.26.2` and ldns `1.9.2` (`drill`)
  compiled from official verified source tarballs on Debian 13 (trixie) slim.
- Drop-in compatibility with `klutchell/unbound`: `/etc/unbound/unbound.conf`,
  `/etc/unbound/custom.conf.d/*.conf`, `/var/unbound/root.key`,
  `/var/unbound/root.hints`, `unbound` service account (101:102), and `drill`
  healthcheck binary.
- Full feature set compiled in: libevent, OpenSSL 3, DNSCrypt, EDNS client
  subnet, cachedb (hiredis), nghttp2, TCP Fast Open, and RFC 5011 DNSSEC root
  trust anchor initialized via `unbound-anchor`.
- Automated 7-step daily CI pipeline: upstream release check, clean `--no-cache`
  build, Trivy and Grype blocking gates, SPDX SBOM, functional and negative
  smoke tests, Docker Hub publishing, automated README/CHANGELOG sync, and
  failure alerting.
