# TOR Container

A tiny container that runs [Tor](https://www.torproject.org) — the privacy network.

By default it works as a **SOCKS5 proxy** on port `9050`. With a single environment variable (`TOR_RELAY=1`) the same container also becomes a **Tor relay** (ORPort `9001` + DirPort `9030`) — it can run as client and relay at the same time.

It's built on [Debian trixie-slim](https://www.debian.org/) with Tor from the official Debian repositories, keeps the image small (~90 MB) and easy to audit. Tor runs as **PID 1**, so the container shuts down gracefully on `SIGTERM` (no `SIGKILL` after timeout).

> When the container starts, the Tor circuit bootstrap process begins. From start to an established connection it can take a few minutes — longer on the very first boot, faster afterwards when `/var/lib/tor` is persisted. Please be patient during this time.

## What This Container Does

- **Client mode (default):** routes your traffic through the Tor network over a SOCKS5 proxy on `9050`, reachable from other machines on your network (`SocksPort 0.0.0.0:9050`).
- **Relay mode (opt-in, `TOR_RELAY=1`):** participates in the Tor network by routing traffic *for other users*, via the ORPort (`9001`) and the directory service DirPort (`9030`), with configurable nickname, contact info and bandwidth limits.
- **Everything is configured via environment variables** — the `torrc` is generated at every start by a small entrypoint script, so there is nothing to edit inside the container.

## Quick Start (published image)

The image is published on Docker Hub as [`eduardoenemark/tor`](https://hub.docker.com/r/eduardoenemark/tor).

### Client mode (recommended)

#### Using Docker Compose

Create a `docker-compose.yml`:

```yaml
version: '3.8'
services:
  tor:
    image: docker.io/eduardoenemark/tor:1.1
    container_name: tor
    restart: always
    stop_grace_period: 5s
    ports:
      - "0.0.0.0:9050:9050/tcp"   # SOCKS5 proxy
    volumes:
      - "~/.cache/log/tor:/var/log/tor"
      - "~/.cache/data/tor:/var/lib/tor"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 256m
```

Then run:

```bash
docker-compose up -d
```

#### Using Podman / Docker directly

```bash
podman run --name tor --restart always --stop-timeout 5 \
  --publish 0.0.0.0:9050:9050/tcp \
  --volume ~/.cache/log/tor:/var/log/tor \
  --volume ~/.cache/data/tor:/var/lib/tor \
  --cpus 1 --memory 256m \
  docker.io/eduardoenemark/tor:1.1
```

### Relay mode

Add `TOR_RELAY=1` (and optionally a nickname / contact info / bandwidth limits):

```yaml
version: '3.8'
services:
  tor:
    image: docker.io/eduardoenemark/tor:1.1
    container_name: tor
    restart: always
    stop_grace_period: 5s
    environment:
      - TOR_RELAY=1
      - TOR_NICKNAME=myrelay          # 1-19 chars, [a-zA-Z0-9]
      - TOR_CONTACT_INFO=you@example.com   # recommended for relays
      - TOR_BANDWIDTH_RATE=5242880    # bytes/s (see note below)
      - TOR_BANDWIDTH_BURST=10485760  # bytes/s
    ports:
      - "0.0.0.0:9050:9050/tcp"   # SOCKS5 (your own traffic)
      - "0.0.0.0:9001:9001/tcp"   # ORPort — relay traffic
      - "0.0.0.0:9030:9030/tcp"   # DirPort — directory service
    volumes:
      - "~/.cache/log/tor:/var/log/tor"
      - "~/.cache/data/tor:/var/lib/tor"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 256m
```

## Build from Source

```bash
git clone https://github.com/eduardoenemark/containers-tor.git
cd containers-tor
./build.sh          # builds localhost/tor:<version> (name/version parsed from OCI labels)
./start.sh          # client mode (compose.yaml)
./start.sh relay    # relay mode (compose-relay.yaml)
./stop.sh
```

## Configuration

### Ports

| Port | Mode | Description |
|---|---|---|
| `9050/tcp` | always | **SOCKS5** proxy port (`SocksPort 0.0.0.0:9050`) |
| `9001/tcp` | relay only | **ORPort** — other Tor nodes connect here to route circuits through your relay |
| `9030/tcp` | relay only | **DirPort** — directory service that serves node/consensus information. Since Tor 0.4.6.1-alpha non-authoritative relays no longer *advertise* this port in the consensus (modern clients fetch directory documents through the ORPort), but it still listens and answers — useful for inspection/replication of node info |

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `TOR_SOCKET_PORT` | `9050` | SOCKS5 port (client mode) |
| `TOR_RELAY` | `0` | Set to `1` to enable relay mode |
| `TOR_OR_PORT` | `9001` | Relay ORPort |
| `TOR_DIR_PORT` | `9030` | Relay DirPort |
| `TOR_NICKNAME` | *(empty → `Unnamed`)* | Relay identity: 1–19 chars, `[a-zA-Z0-9]` only |
| `TOR_CONTACT_INFO` | *(empty)* | How the Tor Project can contact you about the relay (strongly recommended) |
| `TOR_BANDWIDTH_RATE` | `5242880` | Sustained bandwidth limit for relay traffic, **bytes/s** (≈ 40 Mbit/s) |
| `TOR_BANDWIDTH_BURST` | `10485760` | Burst bandwidth limit, **bytes/s** (≈ 84 Mbit/s) |

> **Bandwidth units:** Tor measures `BandwidthRate`/`BandwidthBurst` in **bytes per second**, not bits. The defaults above are 5 / 10 MiB/s (≈ 40 / 84 Mbit/s). If your line is smaller, lower the values — e.g. to cap a home relay at 5 Mbit/s sustained use `625000`. Bandwidth limits are strongly recommended for any relay: they protect your connection from being saturated by relay traffic.

### Volumes

| Path in container | Suggested host path | Purpose |
|---|---|---|
| `/var/log/tor` | `~/.cache/log/tor` | Tor logs (`notices.log` + stdout) |
| `/var/lib/tor` | `~/.cache/data/tor` | Tor state: identity key, geoip, circuit state. Persisting it makes the second and later bootstraps much faster, and for a relay this is where the **long-term identity key** lives — keep the volume if you want to keep your relay's identity |

### How `torrc` is generated

At every start, `/usr/local/bin/tor-entrypoint.sh` regenerates `/etc/tor/torrc` from the environment variables above and then `exec`s Tor as PID 1. There is no static config file in the image: **all configuration happens through environment variables**, and manual edits inside the container are overwritten on restart.

## Usage

### As a SOCKS5 proxy

Point any application at the proxy:

- Host: `localhost` (on the same machine) or the host's IP on your network
- Port: `9050`
- Protocol: **SOCKS5**

```bash
# Your exit IP is now a Tor exit node, not your own IP:
curl --socks5-hostname localhost:9050 https://api.ipify.org

# Official check:
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
# → {"IsTor":true}
```

Browsers, curl, git and most tools support SOCKS5 directly (e.g. `git config --global http.proxy socks5h://127.0.0.1:9050`). If you need a plain HTTP forward proxy instead, see the companion image [`eduardoenemark/tor-proxy`](https://hub.docker.com/r/eduardoenemark/tor-proxy) (Tor + Privoxy on port 55455).

### As a relay

In relay mode Tor keeps working as your SOCKS5 client at the same time — you can route your own traffic through your own relay.

**Reachability:** for your relay to carry *other* nodes' traffic it must be reachable from the Internet — a public IP, or port forwarding for **9001** (and optionally 9030) on your router. The entrypoint sets `Address 127.0.0.1` by default so that bootstrap also works in NAT-only environments (e.g. rootless Podman with slirp4netns); there the relay runs fine for its own circuits, but other nodes cannot route through it. For a real public relay, run on a machine with a public IP, forward the ports, and make sure the advertised address matches (adjust the `Address` line in `tor-entrypoint.sh`).

**Checklist for a public relay:**
1. Public IP or port forwarding for 9001/tcp (and 9030/tcp)
2. `TOR_NICKNAME` set (unique, memorable)
3. `TOR_CONTACT_INFO` set — so the Tor Project can reach you if there are issues with your relay
4. Bandwidth limits sized to what your line can spare
5. Persist `/var/lib/tor` — that's where the relay identity key lives
6. Verify: `curl http://localhost:9030/tor/status` → `OK Tor version=...`

## Logs

- Everything Tor logs at `notice` level goes to **stdout** (`podman logs tor` / `docker logs tor`) and to `/var/log/tor/notices.log` (persisted in the volume).
- Watch for `Bootstrapped 100% (done)` — that's when the proxy is ready.

## Requirements

- Docker or Podman on your system (`podman-compose` if you use the compose files)
- At least **256 MB** of RAM available for the container
- Port `9050` free on the host (and `9001`/`9030` in relay mode)

## Security Note

- **Don't expose the SOCKS port (9050) to the Internet.** It has no authentication — anyone who can reach it can use your exit. Bind it to your LAN only.
- Your ISP will see that you are talking to Tor relays (metadata); Tor protects the content and destination of your traffic, not the fact that you use Tor.
- **Relay mode:** by running a relay you become part of the Tor network. Law enforcement may contact you about traffic that passed through your relay — keep logging minimal (this image logs only `notice` level) and read the [Tor Project's relay guidance](https://support.torproject.org/relay/) before publishing one.
- Review the security and legal implications of using Tor in your jurisdiction.

## Troubleshooting

- **"Connection refused" / nothing responds on 9050 right after boot:** Tor is still bootstrapping (first boot can take several minutes). Wait for `Bootstrapped 100% (done)` in the logs.
- **Port published but SOCKS handshake fails from other machines:** make sure the container listens on all interfaces — this image uses `SocksPort 0.0.0.0:9050` (a bare `SocksPort 9050` binds to loopback only inside the container and silently breaks published ports).
- **Exit IP equals your real IP:** you are not actually going through Tor — check the proxy settings and the bootstrap status in the logs.
- **Relay mode: bootstrap stuck at ~5% behind NAT:** expected in slirp4netns/rootless environments without real interfaces; use host networking or a public IP (see *Reachability* above).
- Check that ports are not already in use on the host and that the volume directories exist with proper permissions.

## Project Structure

```
containers-tor/
├── Containerfile          # debian trixie-slim + tor, OCI labels, entrypoint
├── tor-entrypoint.sh      # generates /etc/tor/torrc from env vars, execs Tor (PID 1)
├── compose.yaml           # client mode
├── compose-relay.yaml     # relay mode (TOR_RELAY=1 + ORPort/DirPort)
├── build.sh               # builds localhost/tor:<version> (name/version from OCI labels)
├── start.sh [client|relay]
└── stop.sh
```

## License

This project is licensed under the [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).
