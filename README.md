# Llama Installer 🚀

Automatic installer for llama.cpp binaries across different platforms and GPU configurations.

## Installation

### Method 1: Install globally (Recommended)

**Install the installer script for easy future use:**

```bash
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh | bash -s -- --install
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
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh | bash
```

**With options:**
```bash
# Preview what will be installed
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh | bash -s -- -n

# Install in custom directory
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh | bash -s -- -d /opt/bin

# Install specific version
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh | bash -s -- -v b7411
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
```

### Direct usage (without global install):
```bash
# Download and run locally
curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/9181758/llama-installer.sh -o llama.sh
chmod +x llama.sh
./llama.sh --help
```

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

### v1.1.0
- **NEW:** Global installer option (`--install`)
- **IMPROVED:** Automatic overwriting, better documentation

### v1.0.0  
- Initial release
- Support for all major platforms
