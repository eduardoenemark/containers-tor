# ----------------------------------------------------------------------
# Base image – slim Debian (trixie) with the latest security updates
# ----------------------------------------------------------------------
FROM docker.io/debian:trixie-20260918-slim

ENV TOR_SOCKET_PORT=9050
ENV TOR_OR_PORT=9001
ENV TOR_DIR_PORT=9030
ENV TOR_RELAY=0
ENV TOR_NICKNAME=""
ENV TOR_CONTACT_INFO=""
ENV TOR_BANDWIDTH_RATE=5242880
ENV TOR_BANDWIDTH_BURST=10485760

ENV REPO_URL=https://github.com/eduardoenemark/containers-tor
ARG CREATED_DATETIME
ENV CREATED_DATETIME=${CREATED_DATETIME}

LABEL org.opencontainers.image.ref.name="tor" \
      org.opencontainers.image.version="1.1" \
      org.opencontainers.image.authors="@eduardoenemark" \
      org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.title="TOR: Debian container with SOCKS5 client and optional relay" \
      org.opencontainers.image.description="A tiny container that runs Tor as a SOCKS5 proxy on ${TOR_SOCKET_PORT} and, optionally (TOR_RELAY=1), as a relay with ORPort ${TOR_OR_PORT} and DirPort ${TOR_DIR_PORT}." \
      org.opencontainers.image.created="${CREATED_DATETIME}" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.purpose="Tor SOCKS5 proxy and optional relay for private browsing" \
      org.opencontainers.image.vendor="t.me/eduardoenemark" \
      org.opencontainers.image.url="${REPO_URL}" \
      org.opencontainers.image.documentation="${REPO_URL}" \
      maintainer="Eduardo Vieira <eduardoenemark@gmail.com>"

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

COPY tor-entrypoint.sh /usr/local/bin/tor-entrypoint.sh
RUN chmod +x /usr/local/bin/tor-entrypoint.sh

VOLUME ["/var/log/tor","/var/lib/tor"]
EXPOSE ${TOR_SOCKET_PORT}/tcp ${TOR_OR_PORT}/tcp ${TOR_DIR_PORT}/tcp

CMD ["/usr/local/bin/tor-entrypoint.sh"]
