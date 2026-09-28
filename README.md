# containers-tor

A lightweight container that runs [Tor](https://www.torproject.org). It works as a **SOCKS5 proxy** on port 9050 and, optionally, as a **Tor relay** (ORPort 9001 + DirPort 9030) — the same container can be both at the same time.

When the container starts, the Tor circuit bootstrap process begins. From start to an established connection it can take a few minutes. Please be patient during this time.

## Quick start (client mode — default)

```bash
./build.sh
./start.sh          # client mode
./start.sh relay    # relay mode
./stop.sh           # podman stop tor
```

Or run directly with podman:

```bash
podman run --name tor --restart always --stop-timeout 5 \
  --publish 0.0.0.0:9050:9050/tcp \
  --volume ~/.cache/log/tor:/var/log/tor \
  --volume ~/.cache/data/tor:/var/lib/tor \
  --cpus 1 --memory 256m localhost/tor:1.1
```

## Relay mode

Set `TOR_RELAY=1` (see `compose-relay.yaml`) to turn the container into a relay. In relay mode Tor also keeps working as a SOCKS5 client — your own traffic can route through your own relay.

### Ports in relay mode

- `9050/tcp`: SOCKS5 proxy port (client, always on).
- `9001/tcp`: **ORPort** — the relay traffic port; other Tor nodes connect here to route circuits through you. Required to be a relay.
- `9030/tcp`: **DirPort** — the directory service; it serves node/consensus information (directory documents) to anyone who asks. Note: since Tor 0.4.6.1-alpha, non-authoritative relays no longer *advertise* this port in the consensus — modern clients download directory documents through the ORPort instead — but the port still listens and serves, which is useful for replication/inspection of node information.

### Relay configuration (environment variables)

| Variable | Default | Description |
|---|---|---|
| `TOR_RELAY` | `0` | `1` enables relay mode |
| `TOR_NICKNAME` | *(empty → `Unnamed`)* | Relay identity: 1–19 chars, `[a-zA-Z0-9]` only |
| `TOR_CONTACT_INFO` | *(empty)* | How the Tor Project can contact you about the relay (recommended) |
| `TOR_BANDWIDTH_RATE` | `5242880` (5 Mbit/s) | Sustained bandwidth limit, bytes/s |
| `TOR_BANDWIDTH_BURST` | `10485760` (10 Mbit/s) | Burst bandwidth limit, bytes/s |

Bandwidth limits are strongly recommended for any relay — they protect your connection from being saturated by relay traffic. Adjust them to what your line can spare.

### Important: reachability

For your relay to actually carry *other* nodes' traffic it must be reachable from the Internet: a public IP, or port forwarding for **9001** (and optionally 9030) on your router. Behind plain NAT the relay still runs and works for its own circuits, but other nodes can't route through it.

## Volumes

- `/var/log/tor`: Tor logs (persisted at `~/.cache/log/tor/`; also visible with `podman logs tor`).
- `/var/lib/tor`: Tor state (identity keys, geoip, circuit state) so restarts don't reset it. For a relay this is where the long-term identity key lives — keep the volume if you want to keep your relay's identity.

## Using the proxy

Configure your applications to use the proxy:

- Host: `localhost` (on this machine) or the machine's IP on your network
- Port: `9050`
- Protocol: **SOCKS5**

Example with curl:

```bash
curl --socks5-hostname localhost:9050 https://check.torproject.org/api/ip
```

## Requirements

- Docker or Podman installed on your system (`podman-compose` for the compose files)
- At least 256MB RAM available for the container
- Ports 9050 (and 9001/9030 in relay mode) available on your host machine

## Troubleshooting

- Wait a few minutes after startup — Tor needs to bootstrap its circuits before the first request succeeds.
- Check that the ports are not already in use.
- Verify the log directories have proper permissions.
- Check the container logs with `podman logs tor`.
- The exit IP should be a Tor exit node, different from your public IP:
  `curl --socks5-hostname localhost:9050 https://api.ipify.org`
- In relay mode, the directory service answers on the DirPort:
  `curl http://localhost:9030/tor/status` → `OK Tor version=...`

## License

This project is licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).
