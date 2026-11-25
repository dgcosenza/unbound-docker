# syntax=docker/dockerfile:1.7

# ---------------------------------------------------------------------------
# NLnet Labs Unbound DNS resolver + ldns (drill) on Debian 13 (trixie-slim).
#
# Drop-in compatible with klutchell/unbound: same /etc/unbound/unbound.conf,
# /etc/unbound/custom.conf.d/*.conf, /var/unbound/root.key, unbound user
# (101:102), drill healthcheck binary, and compiled-in feature flags.
#
# Every version and base digest below is a documented default; CI overrides
# them on each run (see .github/workflows/daily.yml).
# ---------------------------------------------------------------------------

ARG DEBIAN_BASE=debian:trixie-slim@sha256:8aa5a7bf5a1955bddbe7d74fcdd0b91ab30e74362a8b73af672b0481b35b44a0

ARG UNBOUND_VERSION=1.26.2
ARG UNBOUND_SHA256=d8ee7aa6bbb3ff1be7d9e57637d0d0ec2f18273a8efff1a0afe2c665858b96f7

ARG LDNS_VERSION=1.9.2
ARG LDNS_SHA256=b524fa21994b6e834200ceb8c27f1b84bda5982fe35706f058196c079db94d5d

ARG UNBOUND_UID=101
ARG UNBOUND_GID=102

ARG IMAGE_CREATED=""
ARG IMAGE_REVISION=""
ARG IMAGE_SOURCE="https://github.com/dgcosenza/unbound-docker"

# ---- Stage 1: compile ldns (drill) and Unbound from verified source --------
FROM ${DEBIAN_BASE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG UNBOUND_VERSION
ARG UNBOUND_SHA256
ARG LDNS_VERSION
ARG LDNS_SHA256

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y --no-install-recommends upgrade \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        libevent-dev \
        libexpat1-dev \
        libhiredis-dev \
        libnghttp2-dev \
        libsodium-dev \
        libssl-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Build NLnet Labs ldns (drill)
WORKDIR /src/ldns
RUN set -eux; \
    curl -fsSL --retry 3 "https://nlnetlabs.nl/downloads/ldns/ldns-${LDNS_VERSION}.tar.gz" -o ldns.tar.gz; \
    printf '%s  ldns.tar.gz\n' "${LDNS_SHA256}" | sha256sum -c -; \
    tar -xzf ldns.tar.gz --strip-components=1; \
    ./configure \
        --prefix=/opt/usr \
        --with-drill \
        --localstatedir=/var \
        --with-ssl \
        --disable-rpath \
        --disable-shared \
        --disable-static \
        --disable-ldns-config; \
    make -j"$(nproc)"; \
    make install; \
    strip /opt/usr/bin/drill; \
    ln -sf drill /opt/usr/bin/dig; \
    install -Dm644 LICENSE /opt/notices/LICENSE-ldns

# Build NLnet Labs Unbound with full feature parity
WORKDIR /src/unbound
RUN set -eux; \
    curl -fsSL --retry 3 "https://nlnetlabs.nl/downloads/unbound/unbound-${UNBOUND_VERSION}.tar.gz" -o unbound.tar.gz; \
    printf '%s  unbound.tar.gz\n' "${UNBOUND_SHA256}" | sha256sum -c -; \
    tar -xzf unbound.tar.gz --strip-components=1; \
    ./configure \
        --prefix=/opt/usr \
        --with-conf-file=/etc/unbound/unbound.conf \
        --with-run-dir=/var/unbound \
        --with-chroot-dir=/var/unbound \
        --with-pidfile=/var/unbound/unbound.pid \
        --with-rootkey-file=/var/unbound/root.key \
        --disable-static \
        --disable-shared \
        --disable-rpath \
        --enable-dnscrypt \
        --enable-subnet \
        --enable-cachedb \
        --enable-tfo-server \
        --enable-tfo-client \
        --with-pthreads \
        --with-libevent \
        --with-libhiredis \
        --with-libnghttp2 \
        --with-ssl \
        --with-username=unbound; \
    make -j"$(nproc)"; \
    make install; \
    strip \
        /opt/usr/sbin/unbound \
        /opt/usr/sbin/unbound-anchor \
        /opt/usr/sbin/unbound-checkconf \
        /opt/usr/sbin/unbound-control \
        /opt/usr/sbin/unbound-host; \
    install -Dm644 LICENSE /opt/notices/LICENSE-unbound

# Fetch IANA root hints and bootstrap RFC 5011 DNSSEC root trust anchor
WORKDIR /var/unbound
RUN set -eux; \
    curl -fsSL --retry 3 https://www.internic.net/domain/named.root -o /var/unbound/root.hints; \
    { /opt/usr/sbin/unbound-anchor -v -r /var/unbound/root.hints -a /var/unbound/root.key || true; } \
        | tee /dev/stderr | grep -q "success: the anchor is ok"

# ---- Stage 2: fully upgraded Debian 13 runtime OS layer --------------------
FROM ${DEBIAN_BASE} AS os-base

ARG UNBOUND_UID
ARG UNBOUND_GID

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get -y --no-install-recommends upgrade \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libevent-2.1-7t64 \
        libevent-pthreads-2.1-7t64 \
        libexpat1 \
        libhiredis1.1.0 \
        libnghttp2-14 \
        libsodium23 \
        libssl3t64 \
        tini \
        tzdata \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && groupadd --system --gid "${UNBOUND_GID}" unbound \
    && useradd --system --uid "${UNBOUND_UID}" --gid unbound \
        --home-dir /var/unbound --no-create-home --shell /usr/sbin/nologin unbound \
    && install -d -o unbound -g unbound -m 0755 /var/unbound /etc/unbound /etc/unbound/custom.conf.d

# ---- Stage 3: clean multi-arch runtime image (zero base-upgrade waste) -----
FROM scratch

ARG UNBOUND_VERSION
ARG LDNS_VERSION
ARG UNBOUND_UID
ARG UNBOUND_GID
ARG IMAGE_CREATED
ARG IMAGE_REVISION
ARG IMAGE_SOURCE

COPY --from=os-base / /
COPY --from=builder /opt/usr/sbin/ /usr/sbin/
COPY --from=builder /opt/usr/bin/ /usr/bin/
COPY --from=builder /opt/notices/ /usr/share/doc/unbound-notices/
COPY --from=builder --chown=101:102 /var/unbound/root.hints /var/unbound/root.hints
COPY --from=builder --chown=101:102 /var/unbound/root.key /var/unbound/root.key
COPY --chown=101:102 config/unbound.conf /etc/unbound/unbound.conf

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DEBIAN_FRONTEND=noninteractive

RUN unbound -V && unbound-checkconf && drill -v

LABEL org.opencontainers.image.title="NLnet Labs Unbound (Debian 13)" \
      org.opencontainers.image.description="Hardened, multi-arch Debian 13 (trixie-slim) build of NLnet Labs Unbound DNS resolver with DNSSEC and drill, drop-in compatible with klutchell/unbound." \
      org.opencontainers.image.url="https://hub.docker.com/r/dgcosenza/unbound" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.documentation="${IMAGE_SOURCE}#readme" \
      org.opencontainers.image.version="${UNBOUND_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.licenses="BSD-3-Clause AND MIT" \
      org.opencontainers.image.vendor="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.authors="Daniel G. Cosenza from FNX Labs" \
      org.opencontainers.image.base.name="debian:trixie-slim" \
      io.github.dgcosenza.unbound.upstream_version="${UNBOUND_VERSION}" \
      io.github.dgcosenza.unbound.ldns_version="${LDNS_VERSION}"

EXPOSE 53/tcp 53/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD ["drill", "-Q", "@127.0.0.1", "nlnetlabs.nl"]

ENTRYPOINT ["/usr/bin/tini", "--", "unbound"]
