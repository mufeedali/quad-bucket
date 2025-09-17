#!/usr/bin/env python3
import os

# --- ANSI Color Codes ---
C_BLUE = "\033[94m"
C_YELLOW = "\033[93m"
C_GREEN = "\033[92m"
C_BOLD = "\033[1m"
C_END = "\033[0m"  # Resets all text attributes

# The root directory to search for .env files.
# '.' means the directory where the script is run.
ROOT_DIR = "."

print(f"{C_BLUE}{C_BOLD}Starting generation of .env.example files...{C_END}")

found_any = False
for dirpath, _, filenames in os.walk(ROOT_DIR):
    # Skip the root directory itself
    if os.path.samefile(dirpath, ROOT_DIR):
        continue

    if ".env" in filenames:
        found_any = True
        env_file_path = os.path.join(dirpath, ".env")
        example_file_path = os.path.join(dirpath, ".env.example")

        print(f"  -> Found: {C_YELLOW}{env_file_path}{C_END}")

        with (
            open(env_file_path, "r") as infile,
            open(example_file_path, "w") as outfile,
        ):
            for line in infile:
                stripped_line = line.strip()
                # Ignore empty lines and comments
                if not stripped_line or stripped_line.startswith("#"):
                    outfile.write(line)
                    continue

                # Find the position of the first '='
                if "=" in stripped_line:
                    key = stripped_line.split("=", 1)[0]
                    outfile.write(f"{key}=\n")

        print(f"     {C_GREEN}Generated: {C_YELLOW}{example_file_path}{C_END}")

if not found_any:
    print(f"{C_YELLOW}No .env files found in any subdirectories.{C_END}")

print(f"\n{C_GREEN}{C_BOLD}Generation complete.{C_END}")
