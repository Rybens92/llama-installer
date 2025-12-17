# Llama Installer

One-command installer for llama.cpp with automatic GPU detection and updates.

## What you get

- **llama-cli** - Run language models from command line
- **llama-server** - HTTP API server for your models  
- **GPU optimized** - Automatically picks CUDA/Metal/Vulkan build for your system
- **Auto-updates** - Keeps llama.cpp fresh without manual work

## Quick start

Install and run in under 30 seconds:

```bash
# One-line install
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash

# Or install the script globally first, then use anywhere
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- --install
llama-installer  # Use from anywhere after this
```

## What is this?

If you want to run llama.cpp (the popular LLM inference engine), you usually have to:
- Find the right binary for your system
- Manually download it from GitHub releases  
- Figure out if you need CUDA/Metal/Vulkan version
- Update it yourself when new versions come out

This script does all that automatically. It detects your system, finds the best GPU build, downloads and installs it. That's it.

## Installation options

### Method 1: Global install (recommended)

Install the script to your system so you can use it anytime:

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- --install
```

Then use from anywhere:
```bash
llama-installer          # Install latest llama.cpp
llama-installer --help   # Show all options
llama-installer -n       # Preview what will be installed
```

### Method 2: Direct install

Skip the global install and run directly:

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash

# With options:
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -n        # Preview
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -v b7411  # Specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -d /opt/bin # Custom directory
```

## Usage

Basic commands:
```bash
llama-installer              # Install latest version
llama-installer -n           # Preview (safe to run)
llama-installer -v b7411     # Install specific version
llama-installer -u           # Update existing installation
llama-installer -d /custom/path  # Install elsewhere
```

After installation:
```bash
llama-cli --help        # Command line interface
llama-server --help     # HTTP server
```

## Auto-update feature

Set it and forget it - the script can automatically check for and install new llama.cpp versions.

Setup:
```bash
# Check every hour
llama-installer --auto-update hourly

# Check once per day  
llama-installer --auto-update daily
```

Manage:
```bash
llama-installer --auto-update-status    # See current status
llama-installer --auto-update-logs      # View recent activity  
llama-installer --auto-update-disable   # Pause updates
llama-installer --auto-update-remove    # Remove completely
```

Note: Auto-update only works with the globally installed script.

## System requirements

- **OS**: Linux, macOS, Windows (with WSL/Git Bash)
- **Architecture**: x64, ARM64, s390x
- **GPU**: NVIDIA (CUDA), AMD (ROCm), Apple (Metal), Intel (Vulkan), or CPU-only
- **Dependencies**: curl, tar, sha256sum (usually pre-installed)

## Troubleshooting

**"llama-installer: command not found"**
Add to your PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
# Make permanent:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

**"bash: --install: No such file or directory"**
Use this syntax instead:
```bash
curl -fsSL URL | bash -s -- --install
```

**File already exists warning**
Normal behavior - the installer overwrites to ensure latest version.

## How it works

1. Detects your OS, architecture, and GPU type
2. Queries GitHub API for available llama.cpp releases  
3. Picks the best matching binary (GPU-optimized when possible)
4. Downloads and verifies the archive
5. Extracts to ~/.local/bin (or your chosen directory)
6. Optionally sets up auto-update service

The script is smart about versions - it won't re-download if you already have the latest.

## Changes

**v1.3.0**
- Auto-update system with systemd/cron support
- Smart version checking  
- Better GPU detection

**v1.2.0**
- Version comparison - no redundant downloads
- Improved error handling

**v1.1.0** 
- Global installer option
- Better documentation

**v1.0.0**
- Initial release - basic installation support