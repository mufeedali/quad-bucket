# Quad-Bucket

Collection of [quadlets](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).

## Structure

- Pod dirs: `actual/`, `beaver/`, etc.
  - `<pod>.container`: Quadlet unit
  - `container-data/`: Data/config
  - `.env`: Private vars
  - `.env.example`: Template

## Setup

1. Clone repo
2. Symlink: `ln -s (pwd) ~/.config/containers/systemd`
3. `systemctl --user daemon-reload`
4. Copy/edit `.env` from `.env.example`

## Management

- Start: `systemctl --user start <pod>.container`
- Stop: `systemctl --user stop <pod>.container`
- Status: `systemctl --user status <pod>.container`
- Enable: `systemctl --user enable <pod>.container`

## Dev

- Update `.env.example` files with `python3 generate-examples.py`

### Traefik

- Update Cloudflare IPs in `traefik.yaml` with `traefik/cloudflare-updater/update-cloudflare-ips.py`. Automate using timer and service as you see fit.
- Update `traefik.yaml.example` file with `python3 generate-traefik-example.py`.
