# Llama Installer

[![GitHub](https://img.shields.io/badge/GitHub-Rybens92%2Fllama-installer-blue?style=flat-square&logo=github)](https://github.com/Rybens92/llama-installer)

Automatic installer for llama.cpp binaries for different platforms and GPU configurations.

## Description

`llama-installer.sh` is a bash script that automatically downloads and installs the latest llama.cpp binaries from GitHub releases. The script detects the operating system, architecture, and GPU capabilities, then downloads the appropriate version of the binaries.

## Quick Start

**One-line installation:**

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash
```

**With options:**
```bash
# Test before installation (safe)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -n

# Install in custom directory
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -d /opt/bin

# Install specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -v b7411
```

## ⚠️ Security Notice

**Running scripts from the internet can be dangerous.**

- Script is downloaded and executed directly from GitHub
- Ensure the source is trusted (owner's repository)
- For safety, test with `--dry-run` first:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -n
  ```
- You can also download and inspect the script before running:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh -o llama-installer.sh
  # Check file contents
  cat llama-installer.sh
  # If everything looks good, run:
  bash llama-installer.sh
  ```

## Features

- 🔍 **Automatic system detection**: Linux, macOS, Windows (WSL)
- 🎯 **Intelligent GPU selection**: CUDA (NVIDIA), Vulkan (AMD/Intel), Metal (Apple), HIP (AMD ROCm), CPU
- 📦 **Automatic download**: From GitHub releases with SHA256 verification
- 🛠️ **Easy installation**: To `~/.local/bin` with automatic PATH configuration
- 🔄 **Updates**: Ability to force reinstallation
- 📊 **Dry-run mode**: Check what will be installed without downloading

## Usage

### Method 1: Direct from GitHub (Recommended)

**Simplest way - one line:**

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash
```

**With arguments:**

```bash
# Dry-run (test what will be installed)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -n

# Specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -v b7411

# Custom directory
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -d /opt/bin

# Update existing binaries
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -u
```

### Method 2: Download and run locally

**Download and run locally:**

```bash
# Download script
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh -o llama-installer.sh

# Make executable
chmod +x llama-installer.sh

# Run
./llama-installer.sh
```

### Method 4: Install the installer globally (Recommended for frequent use)

**Install the installer script itself:**

```bash
# One-line installation of the installer (CORRECT METHOD)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- --install

# Or pin to specific commit for stability
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/ebe0029/llama-installer.sh | bash -s -- --install

# Alternative: Download and run locally
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh -o llama-installer.sh
chmod +x llama-installer.sh
./llama-installer.sh --install
```

**Then use from anywhere:**

```bash
llama-installer --help      # Show help
llama-installer -n          # Dry run
llama-installer             # Install latest llama.cpp
llama-installer -v b7411    # Install specific version
```

**Features:**
- ✅ Installs to `~/.local/bin/llama-installer`
- ✅ Automatically sets executable permissions
- ✅ Configures PATH for future sessions
- ✅ Verifies installation after setup
- ✅ Supports overwriting existing installations
- ✅ Works with both `master` branch and specific commits

### Basic usage (local file)

```bash
# Install the latest version
./llama-installer.sh

# Install in custom directory
./llama-installer.sh -d /opt/bin

# Check what will be installed (without downloading)
./llama-installer.sh -n
```

### Options

- `-h, --help` - Show help
- `-v, --version VER` - Version to install (default: latest)
- `-d, --dir DIR` - Installation directory (default: `$HOME/.local/bin`)
- `-n, --dry-run` - Show what will be installed without installing
- `-u, --update` - Update existing binaries (alias: `--force`, `--upgrade`)
- `--check-only` - Only check available versions and exit
- `--install` - Install this script to `~/.local/bin/llama-installer` for global use

## Supported Platforms

### Linux (Ubuntu)
- x86_64: CPU, Vulkan
- s390x: CPU

### macOS
- arm64 (Apple Silicon): Metal
- x64 (Intel): CPU

### Windows (WSL/Cygwin)
- x64: CPU, CUDA, Vulkan, SYCL, HIP
- arm64: CPU

### Other Linux distro
- openEuler: x86, aarch64

## How it works

1. **System detection**: Checks OS, architecture, and available GPU
2. **Download information**: Connects to GitHub API to download release list
3. **Binary selection**: Chooses the best available version for the system
4. **Download and verification**: Downloads archive and verifies SHA256 checksum
5. **Installation**: Extracts binaries to selected directory
6. **PATH configuration**: Automatically adds directory to PATH

## Examples

### Quick Install Examples

```bash
# Simplest installation
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash

# Check what will be installed
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -n

# Install with GPU support (CUDA/Vulkan)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -d ~/.local/bin

# Update existing installation
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -u

# NEW: Install the installer globally (recommended for frequent use)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- --install

# Then use from anywhere:
# llama-installer --help
# llama-installer -n
# llama-installer
```

### Advanced Examples

```bash
# Install specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -v b7411

# Install to /opt/bin (requires sudo)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -d /opt/bin

# Combination of options
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -d /opt/bin -v b7411 -n
```

### Using as function

```bash
# After adding function to ~/.bashrc
llama-installer              # Install latest
llama-installer -n           # Dry run
llama-installer -v b7411     # Specific version
llama-installer -u           # Update
```

## Requirements

- `curl` - for downloading files
- `tar` - for extracting tar.gz archives
- `sha256sum` - for verifying checksums
- `jq` - for JSON parsing
- `uname` - for system detection

### Installing dependencies

**Ubuntu/Debian:**
```bash
sudo apt install curl tar jq coreutils
```

**Fedora/RHEL:**
```bash
sudo dnf install curl tar jq coreutils
```

**Arch Linux:**
```bash
sudo pacman -S curl tar jq coreutils
```

**macOS:**
```bash
brew install curl tar jq
```

## After installation

After installation you can use:

```bash
# Command line interface
llama-cli --help

# HTTP server with API
llama-server --help

# Benchmarks
llama-bench --help
```

### PATH update

After installation, to update PATH in the current session:

```bash
source ~/.bashrc  # for bash
source ~/.zshrc   # for zsh
```

## Logging and debugging

The script displays detailed logs with colors:
- 🔵 `[INFO]` - General information
- 🟢 `[SUCCESS]` - Successful operations
- 🟡 `[WARNING]` - Warnings
- 🔴 `[ERROR]` - Errors

## Troubleshooting

### GitHub connection problem
```bash
# Check connection
curl -I https://api.github.com/repos/ggml-org/llama.cpp/releases/latest
```

### Missing binaries after installation
```bash
# Check if files exist
ls -la ~/.local/bin/

# Check PATH
echo $PATH

# Add manually to PATH
export PATH="$HOME/.local/bin:$PATH"
```

### Permission issues
```bash
# Make sure directory exists and is writable
mkdir -p ~/.local/bin
chmod 755 ~/.local/bin
```

### Dry-run verification
```bash
# Check if remote execution works
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- -n

# Check available versions
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash -s -- --check-only
```

## File structure

After installation in `~/.local/bin/` you will find:

```
~/.local/bin/
├── llama-cli              # Main CLI
├── llama-server           # HTTP server
├── llama-bench            # Benchmark
├── libggml*.so            # GGML libraries
└── ...                    # Other tools
```

## License

This script was created for educational purposes. llama.cpp has its own MIT license.

## Support

For issues:

1. Check [official llama.cpp repository](https://github.com/ggml-org/llama.cpp)
2. Check [issues](https://github.com/ggml-org/llama.cpp/issues)
3. Run script with `--dry-run` to check what will be downloaded

## Version Reference

**Current version:** v1.0.0  
**Latest commit:** [7ea47b3](https://github.com/Rybens92/llama-installer/commit/7ea47b3)

### Pin to specific version
```bash
# Use specific commit (more stable)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/7ea47b3/llama-installer.sh | bash

# Or master branch (latest changes)
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh | bash
```

## Troubleshooting

### Common Issues

#### Issue: "bash: --install: Nie ma takiego pliku ani katalogu"
**Problem:** This error occurs when using:
```bash
curl -fsSL URL | bash -- --install
```

**Solution:** Use `bash -s` instead:
```bash
curl -fsSL URL | bash -s -- --install
```

**Why:** When using pipes, arguments after `--` go to the original shell, not the bash process processing the script via stdin.

#### Issue: "Permission denied" 
**Solution:** Make sure you have write permissions to `~/.local/bin`:
```bash
# Check if directory exists and is writable
ls -la ~/.local/bin

# If needed, create directory
mkdir -p ~/.local/bin
```

#### Issue: Command not found after installation
**Solution:** Update your PATH or restart terminal:
```bash
# Add to current session
export PATH="$HOME/.local/bin:$PATH"

# Or add permanently to ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Issue: Installation fails
**Solution:** Try alternative installation methods:
```bash
# Method 1: Download and run locally
curl -fsSL URL -o llama-installer.sh
chmod +x llama-installer.sh
./llama-installer.sh --install

# Method 2: Use wget
wget -qO- URL | bash -s -- --install
```

## Changelog

### v1.1.0
- **NEW:** Added `--install` option for self-installation
- **NEW:** Install script globally to `~/.local/bin/llama-installer`
- **NEW:** Automatic PATH configuration for installed script
- **NEW:** Interactive confirmation for overwriting existing installations
- **NEW:** Installation verification after setup
- **NEW:** Support for both master branch and specific commits
- **IMPROVED:** Updated documentation with global installation examples
- **IMPROVED:** Enhanced help text with new options
- **FIXED:** Documentation for correct pipe usage (`bash -s --` instead of `bash --`)
- **ADDED:** Troubleshooting section with common issues and solutions

### v1.0.0
- First version
- Support for all major platforms
- Automatic GPU detection
- SHA256 verification
- PATH configuration
- **Fixed:** Script execution through pipe (BASH_SOURCE fallback)
- **Added:** Direct GitHub execution support