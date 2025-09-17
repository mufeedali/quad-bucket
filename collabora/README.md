# Collabora Online

LibreOffice in the browser for collaborative editing.

## Environment Variables

- `NEXTCLOUD_DOMAIN`: Nextcloud domain (e.g., `https://nextcloud.example.com`)

## Notes

- Integrates with Nextcloud
- SSL terminated at reverse proxy
- Default port: 9980

## Setup

1. Set `NEXTCLOUD_DOMAIN` in `.env`
2. Configure reverse proxy
3. Install Collabora app in Nextcloud
4. Run: `systemctl --user start collabora.container`

[Collabora docs](https://www.collaboraoffice.com/code/)
