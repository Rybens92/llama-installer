# Llama Installer

Automatic installer for llama.cpp binaries for different platforms and GPU configurations.

## Description

`llama-installer.sh` is a bash script that automatically downloads and installs the latest llama.cpp binaries from GitHub releases. The script detects the operating system, architecture, and GPU capabilities, then downloads the appropriate version of the binaries.

## Features

- 🔍 **Automatic system detection**: Linux, macOS, Windows (WSL)
- 🎯 **Intelligent GPU selection**: CUDA (NVIDIA), Vulkan (AMD/Intel), Metal (Apple), HIP (AMD ROCm), CPU
- 📦 **Automatic download**: From GitHub releases with SHA256 verification
- 🛠️ **Easy installation**: To `~/.local/bin` with automatic PATH configuration
- 🔄 **Updates**: Ability to force reinstallation
- 📊 **Dry-run mode**: Check what will be installed without downloading

## Usage

### Basic usage

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

```bash
# Basic installation
./llama-installer.sh

# Install specific version
./llama-installer.sh -v b7410

# Dry-run to see what will be downloaded
./llama-installer.sh -n

# Update binaries
./llama-installer.sh --update

# Check available versions
./llama-installer.sh --check-only
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

## Changelog

### v1.0.0
- First version
- Support for all major platforms
- Automatic GPU detection
- SHA256 verification
- PATH configuration