#!/usr/bin/env python3
import os
import re

# --- ANSI Color Codes ---
C_BLUE = "\033[94m"
C_YELLOW = "\033[93m"
C_GREEN = "\033[92m"
C_BOLD = "\033[1m"
C_END = "\033[0m"  # Resets all text attributes

# Path to the traefik config file
TRAEFIK_CONFIG_PATH = "traefik/container-config/traefik/traefik.yaml"
EXAMPLE_CONFIG_PATH = "traefik/traefik.yaml.example"

# Sensitive fields to sanitize (field_name: replacement_value)
# Add new fields here as needed
SENSITIVE_FIELDS = {
    "email": "your-email@example.com",
    "network": "your-shared-network",
    # Examples for future use:
    # "storage": "acme.json",
    # "provider": "your-dns-provider",
    # "moduleName": "github.com/your-org/your-plugin",
    # "domain": "example.com",
}

# Email pattern to match and replace
EMAIL_PATTERN = r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"

print(f"{C_BLUE}{C_BOLD}Starting generation of Traefik config example...{C_END}")

if not os.path.exists(TRAEFIK_CONFIG_PATH):
    print(f"{C_YELLOW}Error: {TRAEFIK_CONFIG_PATH} not found!{C_END}")
    exit(1)

print(f"  -> Reading: {C_YELLOW}{TRAEFIK_CONFIG_PATH}{C_END}")

with open(TRAEFIK_CONFIG_PATH, "r") as infile:
    content = infile.read()

# Replace email addresses
content = re.sub(EMAIL_PATTERN, SENSITIVE_FIELDS["email"], content)

# Replace other sensitive fields
for field, replacement in SENSITIVE_FIELDS.items():
    if field == "email":  # Already handled above
        continue

    # Match YAML field patterns like "network: shared-network"
    pattern = rf"^(\s*{field}:\s*)(.+)$"
    content = re.sub(pattern, rf"\1{replacement}", content, flags=re.MULTILINE)

# Ensure the output directory exists
os.makedirs(os.path.dirname(EXAMPLE_CONFIG_PATH), exist_ok=True)

with open(EXAMPLE_CONFIG_PATH, "w") as outfile:
    outfile.write(content)

print(f"     {C_GREEN}Generated: {C_YELLOW}{EXAMPLE_CONFIG_PATH}{C_END}")
print(f"\n{C_GREEN}{C_BOLD}Generation complete.{C_END}")
print(f"{C_BLUE}Sanitized fields:{C_END}")
for field, replacement in SENSITIVE_FIELDS.items():
    print(f"  - {field}: {replacement}")
