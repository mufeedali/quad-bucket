#!/bin/bash
set -e

# --- 1. Setup Environment ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deploy.log"
ARCHIVE_FILE="$LOG_DIR/deploy.log.old"
MAX_SIZE_KB=500  # Rotate if larger than 500KB

# --- 2. Log Rotation Logic ---
if [ -f "$LOG_FILE" ]; then
    # Get file size in KB
    FILE_SIZE_KB=$(du -k "$LOG_FILE" | cut -f1)

    if [ "$FILE_SIZE_KB" -ge "$MAX_SIZE_KB" ]; then
        # Move current log to .old (overwriting the previous .old)
        mv "$LOG_FILE" "$ARCHIVE_FILE"

        # Optional: Add a timestamp header to the new file
        echo "--- Log Rotated on $(date) ---" > "$LOG_FILE"
        echo "Previous logs moved to: $ARCHIVE_FILE" >> "$LOG_FILE"
    fi
fi

# --- 3. Redirect Output ---
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
exec > >(tee -a "$LOG_FILE") 2>&1

echo "------------------------------------------------------"
echo "[$TIMESTAMP] Starting GitOps Update..."
echo "[$TIMESTAMP] Script location: $SCRIPT_DIR"

# --- 4. Find Git Root ---
GIT_ROOT=$(git rev-parse --show-toplevel)

if [ -z "$GIT_ROOT" ]; then
    echo "[$TIMESTAMP] ERROR: Not inside a git repository."
    exit 1
fi

cd "$GIT_ROOT"

# --- 5. Check for Updates ---
echo "[$TIMESTAMP] Fetching origin..."
git fetch origin main

CHANGED_FILES=$(git diff --name-only HEAD origin/main | grep '\.container$' || true)

if [ -z "$CHANGED_FILES" ]; then
    echo "[$TIMESTAMP] No container changes detected. Performing standard pull."
    git merge origin/main
    echo "[$TIMESTAMP] Status: Synced (No Restarts)"
    exit 0
fi

echo "[$TIMESTAMP] Changes detected in: $(echo $CHANGED_FILES | xargs)"

# --- 6. Apply & Restart ---
echo "[$TIMESTAMP] Merging changes from origin/main..."
git merge origin/main

echo "[$TIMESTAMP] Pushing changes to GitHub mirror..."
git push github main

echo "[$TIMESTAMP] Reloading systemd daemon..."
systemctl --user daemon-reload

for file in $CHANGED_FILES; do
    FILENAME=$(basename "$file")
    SERVICE_NAME="${FILENAME%.*}.service"

    echo "[$TIMESTAMP] Processing: $SERVICE_NAME"

    if systemctl --user is-failed --quiet "$SERVICE_NAME"; then
        echo "[$TIMESTAMP] STATUS: $SERVICE_NAME is in 'failed' state. Attempting full restart..."
        if systemctl --user restart "$SERVICE_NAME"; then
             echo "[$TIMESTAMP] SUCCESS: $SERVICE_NAME restarted (recovered from failed state)."
        else
             echo "[$TIMESTAMP] ERROR: Failed to restart $SERVICE_NAME"
        fi
    else
        echo "[$TIMESTAMP] STATUS: $SERVICE_NAME is not failed. Attempting try-restart..."
        if systemctl --user try-restart "$SERVICE_NAME"; then
            echo "[$TIMESTAMP] SUCCESS: $SERVICE_NAME try-restarted."
        else
            echo "[$TIMESTAMP] ERROR: Failed to try-restart $SERVICE_NAME"
        fi
    fi

    echo "[$TIMESTAMP] Cleaning up unused Podman resources..."
    podman system prune -a
done

echo "[$TIMESTAMP] Update Batch Complete."
echo "------------------------------------------------------"
