Trying to keep it as simple as possible.

Uploads aren't on the disk: `immich-mount.service` mounts `$RCLONE_REMOTE:` at `$UPLOAD_LOCATION`, both from `.env`. The remote needs to exist in rclone's config.
