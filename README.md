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

### Container File Format

All `.container` files follow this structure:

```
[Unit]
[Service]
[Install]
[Container]
  # Container properties
    ContainerName -> Image -> AutoUpdate -> Pull
  # Environment options
    Environment vars -> EnvironmentFile
  # User options
    User -> Group -> UserNS
  # Network options
    Network -> NetworkAlias -> PublishPort
  # Volume binds
    Data -> Config -> System files
  # Traefik Labels
    enable -> rule -> entrypoints -> middlewares -> services
  # Glance Labels
    name -> icon -> url -> description -> id
```

See `beaver.container` for reference.

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

## GitOps

I auto-update container images via Renovate + auto-deploy on push. Well, not truly "auto" since I merge manually to make sure there's some level of stability via pinning.

```
Renovate (hourly + on-push) -> PR with update -> Manual Merge via Web UI or Mobile app
-> Update .container images -> Forgejo Push Trigger -> Webhook
-> touch trigger -> systemd .path -> Pull changes -> Restart relevant containers
```

## Dev

- Update `.env.example` files with `qh generate env` (quadlet-helper). There's also a pre-commit hook in the .githooks directory.

### Traefik

- Update Cloudflare IPs in `traefik.yaml` with `qh cloudflare run`. Automate using `qh cloudflare install`.
- Update `traefik.yaml.example` file with `qh generate traefik`.
