#!/usr/bin/env python3
import requests
import yaml
import os
import sys
from datetime import datetime

# --- ANSI Color Codes ---
C_BLUE = "\033[94m"
C_YELLOW = "\033[93m"
C_GREEN = "\033[92m"
C_RED = "\033[91m"
C_BOLD = "\033[1m"
C_END = "\033[0m"

# Configuration
TRAEFIK_CONFIG_PATH = "../container-config/traefik/traefik.yaml"
CLOUDFLARE_IPV4_URL = "https://www.cloudflare.com/ips-v4"
CLOUDFLARE_IPV6_URL = "https://www.cloudflare.com/ips-v6"


def fetch_cloudflare_ips():
    """Fetch the latest Cloudflare IP ranges from their official endpoints."""
    print(f"{C_BLUE}Fetching latest Cloudflare IP ranges...{C_END}")

    try:
        # Fetch IPv4 ranges
        ipv4_response = requests.get(CLOUDFLARE_IPV4_URL, timeout=10)
        ipv4_response.raise_for_status()
        ipv4_ranges = [
            ip.strip() for ip in ipv4_response.text.strip().split("\n") if ip.strip()
        ]

        # Fetch IPv6 ranges
        ipv6_response = requests.get(CLOUDFLARE_IPV6_URL, timeout=10)
        ipv6_response.raise_for_status()
        ipv6_ranges = [
            ip.strip() for ip in ipv6_response.text.strip().split("\n") if ip.strip()
        ]

        all_ranges = ipv4_ranges + ipv6_ranges
        print(
            f"{C_GREEN}✓ Fetched {len(ipv4_ranges)} IPv4 and {len(ipv6_ranges)} IPv6 ranges{C_END}"
        )
        return all_ranges

    except requests.RequestException as e:
        print(f"{C_RED}✗ Error fetching Cloudflare IPs: {e}{C_END}")
        return None


def read_traefik_config():
    """Read the current Traefik configuration."""
    if not os.path.exists(TRAEFIK_CONFIG_PATH):
        print(f"{C_RED}✗ Traefik config not found: {TRAEFIK_CONFIG_PATH}{C_END}")
        return None

    try:
        with open(TRAEFIK_CONFIG_PATH, "r") as f:
            return yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"{C_RED}✗ Error parsing YAML: {e}{C_END}")
        return None


def update_cloudflare_ips_in_config(config, new_ips):
    """Update the Cloudflare IPs in the configuration."""
    if "cloudflare-ips" not in config:
        print(f"{C_RED}✗ 'cloudflare-ips' section not found in config{C_END}")
        return False

    current_ips = config["cloudflare-ips"].get("trustedIPs", [])

    # Compare current vs new IPs
    current_set = set(current_ips)
    new_set = set(new_ips)

    if current_set == new_set:
        print(f"{C_GREEN}✓ Cloudflare IPs are already up to date{C_END}")
        return False

    # Show changes
    added = new_set - current_set
    removed = current_set - new_set

    if added:
        print(f"{C_YELLOW}+ Added IPs: {', '.join(sorted(added))}{C_END}")
    if removed:
        print(f"{C_YELLOW}- Removed IPs: {', '.join(sorted(removed))}{C_END}")

    # Update the config
    config["cloudflare-ips"]["trustedIPs"] = sorted(new_ips)
    return True


def write_traefik_config(config):
    """Write the updated configuration back to file."""
    try:
        # Read the original file to preserve formatting and comments
        with open(TRAEFIK_CONFIG_PATH, "r") as f:
            original_content = f.read()

        # Create a backup
        backup_path = (
            f"{TRAEFIK_CONFIG_PATH}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        )
        with open(backup_path, "w") as f:
            f.write(original_content)
        print(f"{C_BLUE}📁 Backup created: {backup_path}{C_END}")

        # Find and replace the cloudflare-ips section
        lines = original_content.split("\n")
        new_lines = []
        in_cloudflare_section = False
        indent = ""

        for line in lines:
            if line.strip().startswith("cloudflare-ips:"):
                new_lines.append(line)
                in_cloudflare_section = True
                continue
            elif in_cloudflare_section:
                if line.strip().startswith("trustedIPs:"):
                    # Detect indentation
                    indent = line[: line.index("trustedIPs:")]
                    new_lines.append(line)
                    # Add all the new IPs
                    for ip in config["cloudflare-ips"]["trustedIPs"]:
                        new_lines.append(f'{indent}    - "{ip}"')
                    continue
                elif line.strip().startswith('- "') and "trustedIPs" in "".join(
                    new_lines[-5:]
                ):
                    # Skip old IP entries
                    continue
                elif (
                    line.strip()
                    and not line.startswith(" ")
                    and not line.startswith("\t")
                ):
                    # We've hit the next section
                    in_cloudflare_section = False
                    new_lines.append(line)
                elif not line.strip():
                    # Empty line
                    new_lines.append(line)
                else:
                    # Still in cloudflare section but not an IP
                    new_lines.append(line)
            else:
                new_lines.append(line)

        # Write the updated content
        with open(TRAEFIK_CONFIG_PATH, "w") as f:
            f.write("\n".join(new_lines))

        print(f"{C_GREEN}✓ Configuration updated successfully{C_END}")
        return True

    except Exception as e:
        print(f"{C_RED}✗ Error writing config: {e}{C_END}")
        return False


def restart_traefik():
    """Restart Traefik container using systemctl."""
    print(f"{C_BLUE}Restarting Traefik container...{C_END}")

    try:
        import subprocess

        # Try to restart traefik.container via systemctl
        result = subprocess.run(
            ["systemctl", "--user", "restart", "traefik.container"],
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode == 0:
            print(f"{C_GREEN}✓ Traefik restarted successfully{C_END}")
            return True
        else:
            print(f"{C_RED}✗ Failed to restart Traefik: {result.stderr.strip()}{C_END}")
            print(
                f"{C_YELLOW}💡 Please restart manually: systemctl --user restart traefik.container{C_END}"
            )
            return False

    except subprocess.TimeoutExpired:
        print(f"{C_RED}✗ Timeout restarting Traefik{C_END}")
        print(
            f"{C_YELLOW}💡 Please restart manually: systemctl --user restart traefik.container{C_END}"
        )
        return False
    except Exception as e:
        print(f"{C_RED}✗ Error restarting Traefik: {e}{C_END}")
        print(
            f"{C_YELLOW}💡 Please restart manually: systemctl --user restart traefik.container{C_END}"
        )
        return False


def main():
    print(f"{C_BOLD}{C_BLUE}Cloudflare IP Updater for Traefik{C_END}")
    print(f"{C_BLUE}{'=' * 40}{C_END}")

    # Fetch latest IPs
    new_ips = fetch_cloudflare_ips()
    if not new_ips:
        sys.exit(1)

    # Read current config
    config = read_traefik_config()
    if not config:
        sys.exit(1)

    # Update IPs in config
    needs_update = update_cloudflare_ips_in_config(config, new_ips)
    if not needs_update:
        print(f"\n{C_GREEN}{C_BOLD}No updates needed!{C_END}")
        sys.exit(0)

    # Write updated config
    if write_traefik_config(config):
        print(f"\n{C_GREEN}{C_BOLD}✓ Cloudflare IPs updated successfully!{C_END}")

        # Restart Traefik to apply changes
        if restart_traefik():
            print(f"{C_GREEN}{C_BOLD}✓ Configuration applied successfully!{C_END}")
        else:
            print(
                f"{C_YELLOW}⚠ Configuration updated but Traefik restart failed{C_END}"
            )
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
