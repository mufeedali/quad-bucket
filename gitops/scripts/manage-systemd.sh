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
    "gitops-update-scheduler.service:gitops/system/gitops-update-scheduler.service"
    "gitops-update.timer:gitops/system/gitops-update.timer"
    "gitops-update.service:gitops/system/gitops-update.service"
)

# --- Helper Functions ---
function log() {
    echo "[manage-systemd] $1"
}

function get_version() {
    local file="$1"
    if [ -f "$file" ]; then
        # Extract the number from "# VERSION=X"
        local ver=$(head -n 1 "$file" | grep -oP '^# VERSION=\K.*')
        echo "${ver:-none}"
    else
        echo "missing"
    fi
}

function status() {
    log "Checking systemd unit versions..."
    printf "%-35s %-12s %-15s %s\n" "UNIT" "REPO VER" "INSTALLED VER" "STATUS"
    echo "----------------------------------------------------------------------------"
    
    local all_ok=true
    
    for entry in "${UNITS[@]}"; do
        IFS=":" read -r unit_name rel_path <<< "$entry"
        source_path="$REPO_ROOT/$rel_path"
        target_path="$SYSTEMD_USER_DIR/$unit_name"
        
        repo_ver=$(get_version "$source_path")
        installed_ver=$(get_version "$target_path")
        
        status_msg=""
        if [ "$installed_ver" = "missing" ]; then
            status_msg="[NOT INSTALLED]"
            all_ok=false
        elif [ "$repo_ver" != "$installed_ver" ]; then
            status_msg="[OUT OF DATE]"
            all_ok=false
        else
            status_msg="[OK]"
        fi
        
        printf "%-35s %-12s %-15s %s\n" "$unit_name" "$repo_ver" "$installed_ver" "$status_msg"
    done
    
    if [ "$all_ok" = false ]; then
        echo ""
        log "Some units need updating. Run: $0 install"
    else
        echo ""
        log "All units are up to date."
    fi
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

        log "Copying $unit_name -> $rel_path"
        # If it's a symlink, remove it first
        if [ -L "$target_path" ]; then
            rm "$target_path"
        fi
        cp "$source_path" "$target_path"
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
            log "Removing $unit_name..."
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
    status)
        status
        ;;
    install)
        install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "Usage: $0 {status|install|uninstall}"
        exit 1
        ;;
esac
