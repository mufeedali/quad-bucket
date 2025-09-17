# Code Server

VS Code in the browser.

## Environment Variables

- `TZ`: Timezone (e.g., `UTC`)
- `PROXY_DOMAIN`: Domain for access
- `DEFAULT_WORKSPACE`: Path to workspace

## Configuration

- SSH keys in `container-data/code-server/config/.ssh/`
- Extensions/settings persisted in `container-data/code-server/config/`

## Setup

1. Set env vars in `.env`
2. Create workspace directory
3. Run: `systemctl --user start code-server.container`

[LinuxServer docs](https://docs.linuxserver.io/images/docker-code-server/)
