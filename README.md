# Quad-Bucket

Collection of [quadlets](https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html).

I also make use of some compose stacks: [`compose-bucket`](https://github.com/mufeedali/compose-bucket).

## Structure

- Service-based dirs: `actual/`, `beaver/`, etc.
  - `<pod>.container`: Quadlet unit
  - `container-data/`: Data
  - `container-config/`: Config
  - `.env`: Private vars
  - `.env.example`: Template

## Setup

1. Clone repo
2. Symlink: `ln -s (pwd) ~/.config/containers/systemd`
3. `systemctl --user daemon-reload`
4. Copy/edit `.env` from `.env.example`

## Management

- Start: `systemctl --user start <service>.container`
- Stop: `systemctl --user stop <service>.container`
- Status: `systemctl --user status <service>.container`
- Enable: `systemctl --user enable <service>.container`

## Dev

- Update `.env.example` files with `qh generate env` (quadlet-helper)

### Traefik

- Update Cloudflare IPs in `traefik.yaml` with `qh cloudflare run`. Automate using `qh cloudflare install`.
- Update `traefik.yaml.example` file with `qh generate traefik`.
