# Pocket ID

OIDC provider with passwordless authentication via passkeys.

## Environment Variables

- `PUID`/`GUID`: User/group IDs
- `POCKET_APP_URL`: App URL
- `POCKET_MAXMIND_LICENSE_KEY`: MaxMind license key

## Setup

1. Get MaxMind license
2. Set env vars in `.env`
3. Run: `systemctl --user start pocket-id.container`
4. Configure apps for OIDC

[GitHub](https://github.com/stonith404/pocket-id)
