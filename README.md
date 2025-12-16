# Llama Installer 🚀

Automatic installer for llama.cpp binaries across different platforms and GPU configurations.

## Installation

### Method 1: Install globally (Recommended)

**Install the installer script for easy future use:**

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- --install
```

**Then use from anywhere:**
```bash
llama-installer --help      # Show help
llama-installer             # Install latest llama.cpp  
llama-installer -n          # Preview installation
```

### Method 2: Direct installation

**Install llama.cpp directly without global installer:**

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash
```

**With options:**
```bash
# Preview what will be installed
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -n

# Install in custom directory
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -d /opt/bin

# Install specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh | bash -s -- -v b7411
```

## Usage

### After global installation:
```bash
# Show all available options
llama-installer --help

# Test what will be installed (safe preview)
llama-installer -n

# Install latest llama.cpp
llama-installer

# Install specific version
llama-installer -v b7411

# Update existing installation
llama-installer -u

# Enable auto-update (hourly/daily)
llama-installer --auto-update hourly   # Check every hour
llama-installer --auto-update daily    # Check once a day

# Manage auto-update service
llama-installer --auto-update-status   # Show current status
llama-installer --auto-update-logs     # View logs
llama-installer --auto-update-disable  # Stop auto-updates
llama-installer --auto-update-remove   # Remove auto-update completely
```

### Direct usage (without global install):
```bash
# Download and run locally
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/630ec7c/llama-installer.sh -o llama.sh
chmod +x llama.sh
./llama.sh --auto-update hourly        # Setup auto-update
```

## Auto-Update Feature

The installer includes a powerful auto-update system that can automatically check for and install new versions of llama.cpp.

### Setup Auto-Update

Choose your preferred update frequency:

```bash
# Check for updates every hour
llama-installer --auto-update hourly

# Check for updates once per day (recommended)
llama-installer --auto-update daily
```

### Manage Auto-Update

Monitor and control the auto-update service:

```bash
# Check current status and configuration
llama-installer --auto-update-status

# View recent update activity and logs
llama-installer --auto-update-logs

# Temporarily disable auto-updates
llama-installer --auto-update-disable

# Re-enable auto-updates
llama-installer --auto-update-enable

# Permanently remove auto-update (with confirmation)
llama-installer --auto-update-remove

# Run manual update check
llama-installer --auto-update-check
```

### Auto-Update Requirements

- **Local Installation Required**: Auto-update only works with locally installed script
- **Systemd Support**: Uses systemd timers by default (Linux systems)
- **Fallback Support**: Falls back to cron on systems without systemd
- **Configuration**: Settings stored in `~/.local/share/llama-installer/auto-update.conf`

### How It Works

1. **Version Detection**: Uses `llama-server --version` to check installed version
2. **GitHub Comparison**: Compares with latest available version from GitHub
3. **Smart Updates**: Only downloads and installs when new version is available
4. **Logging**: All activities logged to systemd journal and local log files
5. **Configuration**: Maintains history of last check time and installed version

## Troubleshooting

### "bash: --install: Nie ma takiego pliku ani katalogu"
**Fix:** Use `bash -s --` instead of `bash --`
```bash
curl -fsSL URL | bash -s -- --install
```

### "File already exists" warning
**Info:** This is normal - the installer automatically overwrites existing files to ensure you have the latest version.

### "llama-installer: command not found"
**Fix:** Add to PATH
```bash
export PATH="$HOME/.local/bin:$PATH"
# Or add permanently to ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

## Changelog

### v1.3.0
- **NEW:** Auto-update functionality for llama.cpp
- **NEW:** Systemd timer support for automatic updates (hourly/daily intervals)
- **NEW:** Auto-update management commands (status, logs, enable, disable, remove)
- **NEW:** Configuration file support for auto-update preferences
- **NEW:** Fallback cron support for systems without systemd
- **NEW:** Version comparison for intelligent update detection
- **IMPROVED:** Enhanced version checking with llama-server --version integration

### v1.2.0
- **NEW:** Smart version checking for --update/-u flag
- **IMPROVED:** No longer downloads same version when already up-to-date
- **IMPROVED:** Better error handling for broken binaries

### v1.1.0
- **NEW:** Global installer option (`--install`)
- **IMPROVED:** Automatic overwriting, better documentation

### v1.0.0  
- Initial release
- Support for all major platforms
