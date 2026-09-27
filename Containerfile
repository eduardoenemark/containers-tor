# ----------------------------------------------------------------------
# Base image – slim Debian (trixie) with the latest security updates
# ----------------------------------------------------------------------
FROM docker.io/debian:trixie-20251229-slim

# ---------------------------------------------------------------
# 1. Port variable – makes it easy to change the public port later
# ---------------------------------------------------------------
# default Tor SOCKS5 listening port
ENV TOR_SOCKET_PORT=9050

# repository url
ENV REPO_URL=https://github.com/eduardoenemark/containers-tor

# build date/time
ARG CREATED_DATETIME
ENV CREATED_DATETIME=${CREATED_DATETIME}

# ------------------------------------------------------------------
# 2. Labels – OCI image metadata + extra documentation labels
# ------------------------------------------------------------------
LABEL org.opencontainers.image.ref.name="tor" \
      org.opencontainers.image.version="1.1" \
      org.opencontainers.image.authors="@eduardoenemark" \
      org.opencontainers.image.source="${REPO_URL}" \
      org.opencontainers.image.title="TOR: Debian container with SOCKS5 proxy" \
      org.opencontainers.image.description="A tiny container that runs Tor and exposes a SOCKS5 proxy on ${TOR_SOCKET_PORT}." \
      org.opencontainers.image.created="${CREATED_DATETIME}" \
      org.opencontainers.image.licenses="GPL-3.0-only" \
      org.opencontainers.image.purpose="Tor SOCKS5 proxy for private browsing" \
      org.opencontainers.image.vendor="t.me/eduardoenemark" \
      org.opencontainers.image.url="${REPO_URL}" \
      org.opencontainers.image.documentation="${REPO_URL}" \
      maintainer="Eduardo Vieira <eduardoenemark@gmail.com>"

# ------------------------------------------------------------------
# 3. Install required packages
# ------------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates tor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

# ---------------------------------------------------------------
# 4. Minimal torrc – bind the SOCKS port to all interfaces so the
#    published port (podman -p) is reachable from other machines
# ---------------------------------------------------------------
RUN printf 'SocksPort 0.0.0.0:%s\n' "${TOR_SOCKET_PORT}" > /etc/tor/torrc

# ------------------------------------------------------------------
# 5. Declare runtime volumes – they are useful for persistence & debugging
# ------------------------------------------------------------------
VOLUME ["/var/log/tor","/var/lib/tor"]

# ------------------------------------------------------------------
# 6. Expose the public port (the value comes from the variable above)
# ------------------------------------------------------------------
EXPOSE ${TOR_SOCKET_PORT}/tcp

# ------------------------------------------------------------------
# 7. Entrypoint – start Tor in the foreground, logging to /var/log/tor
# ------------------------------------------------------------------
CMD ["/bin/bash","-c","tor 2>&1 | tee -a /var/log/tor/notices.log"]
