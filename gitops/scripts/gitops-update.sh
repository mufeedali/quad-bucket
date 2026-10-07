#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deploy.log"
ARCHIVE_FILE="$LOG_DIR/deploy.log.old"
MAX_SIZE_KB=500

if [ -f "$LOG_FILE" ]; then
	FILE_SIZE_KB=$(du -k "$LOG_FILE" | cut -f1)
	if [ "$FILE_SIZE_KB" -ge "$MAX_SIZE_KB" ]; then
		mv "$LOG_FILE" "$ARCHIVE_FILE"
		echo "--- Log rotated on $(date) ---" >"$LOG_FILE"
	fi
fi

exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

exec 9>"$LOG_DIR/update.lock"
if ! flock -n 9; then
	log "Another update is already running, skipping."
	exit 0
fi

echo "------------------------------------------------------"
log "Starting GitOps Update..."

GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT"

log "Fetching origin..."
git fetch origin main

CHANGED_FILES=$(git diff --name-only HEAD origin/main | grep '\.container$' || true)

if [ -z "$CHANGED_FILES" ]; then
	log "No container changes detected. Performing standard pull."
	git pull --ff-only origin main
	log "Status: Synced (No Restarts)"
	exit 0
fi

log "Changes detected in: $CHANGED_FILES"

log "Merging changes from origin/main..."
git pull --ff-only origin main

log "Pushing changes to GitHub mirror..."
git push github main || log "Mirror push failed, continuing."

log "Reloading systemd daemon..."
systemctl --user daemon-reload

failed=()

for file in $CHANGED_FILES; do
	SERVICE_NAME="${file##*/}"
	SERVICE_NAME="${SERVICE_NAME%.*}.service"

	log "Processing: $SERVICE_NAME"
	if ! systemctl --user is-failed --quiet "$SERVICE_NAME" &&
		! systemctl --user is-active --quiet "$SERVICE_NAME"; then
		log "Not running, skipping: $SERVICE_NAME"
		continue
	fi

	if ! systemctl --user restart "$SERVICE_NAME"; then
		log "Restart failed: $SERVICE_NAME"
		failed+=("$SERVICE_NAME")
		continue
	fi

	if ! systemctl --user is-active --quiet "$SERVICE_NAME"; then
		log "Not active after restart: $SERVICE_NAME"
		failed+=("$SERVICE_NAME")
	fi
done

log "Cleaning up unused Podman resources..."
podman system prune -a -f

if [ ${#failed[@]} -gt 0 ]; then
	log "Update finished with failures: ${failed[*]}"
	exit 1
fi

log "Update complete."
echo "------------------------------------------------------"
