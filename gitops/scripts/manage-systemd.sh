#!/bin/bash
set -e

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve repo root (grandparent of scripts/ i.e. quad-bucket/)
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# List of units to manage. Format: "UnitName:RelativePathFromRepoRoot"
UNITS=(
    "renovate.timer:gitops/renovate/renovate.timer"
    "renovate-push.timer:gitops/renovate/renovate-push.timer"
    "renovate-scheduler.service:gitops/renovate/renovate-scheduler.service"
    "renovate.path:gitops/renovate/renovate.path"
    "gitops-update.path:gitops/system/gitops-update.path"
    "gitops-update.service:gitops/system/gitops-update.service"
)

# --- Helper Functions ---
function log() {
    echo "[manage-systemd] $1"
}

function install() {
    log "Ensuring systemd user directory exists: $SYSTEMD_USER_DIR"
    mkdir -p "$SYSTEMD_USER_DIR"

    for entry in "${UNITS[@]}"; do
        IFS=":" read -r unit_name rel_path <<< "$entry"
        source_path="$REPO_ROOT/$rel_path"
        target_path="$SYSTEMD_USER_DIR/$unit_name"

        if [ ! -f "$source_path" ]; then
            log "ERROR: Source file not found: $source_path"
            exit 1
        fi

        log "Linking $unit_name -> $rel_path"
        ln -sf "$source_path" "$target_path"
    done

    log "Reloading systemd daemon..."
    systemctl --user daemon-reload
    log "Installation complete."
    log "To start, run: systemctl --user enable --now renovate.timer renovate.path gitops-update.path"
}

function uninstall() {
    for entry in "${UNITS[@]}"; do
        IFS=":" read -r unit_name rel_path <<< "$entry"
        target_path="$SYSTEMD_USER_DIR/$unit_name"

        # Attempt to stop/disable if active
        if systemctl --user is-active --quiet "$unit_name" 2>/dev/null; then
            log "Stopping $unit_name..."
            systemctl --user stop "$unit_name"
        fi

        if systemctl --user is-enabled --quiet "$unit_name" 2>/dev/null; then
             log "Disabling $unit_name..."
             systemctl --user disable "$unit_name"
        fi

        if [ -L "$target_path" ] || [ -f "$target_path" ]; then
            log "Removing link $unit_name..."
            rm "$target_path"
        else
            log "Skipping $unit_name (not found)"
        fi
    done

    log "Reloading systemd daemon..."
    systemctl --user daemon-reload
    log "Uninstallation complete."
}

# --- Main Execution ---
case "$1" in
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {install|uninstall}"
        exit 1
        ;;
esac
