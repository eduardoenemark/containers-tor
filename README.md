# containers-tor

A lightweight container that runs [Tor](https://www.torproject.org) and exposes a **SOCKS5 proxy** on port 9050. It's possible to browse the web, watch videos, and download files through it. Keep in mind that if your Internet connection is slow, your experience will be poor.

When the container starts, the Tor circuit bootstrap process begins. From start to an established connection it can take a few minutes. Please be patient during this time.

This container sets up a private proxy that:

- Routes your internet traffic through the Tor network
- Provides SOCKS5 proxy functionality (port 9050)
- Offers good performance for data communication
- Protects your privacy by anonymizing your traffic

> HTTP/HTTPS forward-proxy on top of Tor? See the sibling project [containers-tor-proxy](https://github.com/eduardoenemark/containers-tor-proxy).

## Quick start

### 1. Build the image

```bash
./build.sh
```

The image is tagged from the Containerfile labels (currently `tor:1.1`).

### 2. Run the container

Create a `compose.yaml` with the following content (already included in this repo):

```yaml
version: '3.8'
services:
  tor:
    image: localhost/tor:1.1
    container_name: tor
    restart: always
    stop_grace_period: 5s
    ports:
      # Tor SOCKS5 proxy port
      - "0.0.0.0:9050:9050/tcp"
    volumes:
      - "~/.cache/log/tor:/var/log/tor"
      - "~/.cache/data/tor:/var/lib/tor"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 256m
```

Or run it directly with podman:

```bash
podman run \
  --name tor \
  --restart always \
  --stop-timeout 5 \
  --publish 0.0.0.0:9050:9050/tcp \
  --volume ~/.cache/log/tor:/var/log/tor \
  --volume ~/.cache/data/tor:/var/lib/tor \
  --cpus 1 \
  --memory 256m \
  localhost/tor:1.1
```

Or use the helper scripts:

```bash
./start.sh   # podman-compose up -d
./stop.sh    # podman stop tor
```

## Ports

- `9050/tcp`: Tor SOCKS5 proxy port (the only service exposed).

The container binds the SOCKS port to **all interfaces** inside the container (`SocksPort 0.0.0.0:9050`), so the published port works from other machines on your network — not just localhost.

## Volumes

- `/var/log/tor`: Tor logs (persisted at `~/.cache/log/tor/`).
- `/var/lib/tor`: Tor state (geoip, circuit state) so restarts don't reset it.

## Using the proxy

Configure your applications to use the proxy:

- Host: `localhost` (on this machine) or the machine's IP on your network
- Port: `9050`
- Protocol: **SOCKS5**

Example with curl:

```bash
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

If you need an HTTP/HTTPS forward proxy instead, use [containers-tor-proxy](https://github.com/eduardoenemark/containers-tor-proxy) (port 55455).

## Requirements

- Docker or Podman installed on your system (`podman-compose` for the compose file)
- At least 256MB RAM available for the container
- Port 9050 available on your host machine

All logs are stored in the `~/.cache/log/tor/` directory on your host machine.

## Troubleshooting

- Wait a few minutes after startup — Tor needs to bootstrap its circuits before the first request succeeds.
- Check that port 9050 is not already in use.
- Verify the log directories have proper permissions.
- Check the container logs with `docker logs tor` or `podman logs tor`.
- The exit IP should be a Tor exit node, different from your public IP:
  `curl --socks5-hostname localhost:9050 https://api.ipify.org`

## License

This project is licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).
