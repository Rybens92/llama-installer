#!/bin/bash

# llama-installer.sh - Automatic installer for llama.cpp binaries
# Version: 1.3.0
# Author: OpenHands
# Description: Downloads and installs the latest llama.cpp binaries from GitHub releases

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="llama-installer"
readonly REPO_OWNER="ggml-org"
readonly REPO_NAME="llama.cpp"
readonly DEFAULT_INSTALL_DIR="$HOME/.local/bin"
readonly GITHUB_API_URL="https://api.github.com"

# Auto-update configuration
readonly AUTO_UPDATE_CONFIG_DIR="$HOME/.local/share/llama-installer"
readonly AUTO_UPDATE_CONFIG_FILE="$AUTO_UPDATE_CONFIG_DIR/auto-update.conf"
readonly AUTO_UPDATE_LOG_FILE="$AUTO_UPDATE_CONFIG_DIR/auto-update.log"
readonly AUTO_UPDATE_SERVICE_NAME="llama-installer-auto.service"
readonly AUTO_UPDATE_TIMER_NAME="llama-installer-auto.timer"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Global variables
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
VERSION="latest"
DRY_RUN=false
UPDATE=false

# Funkcje pomocnicze
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help display function
show_help() {
    cat << EOF
$SCRIPT_NAME - Automatic llama.cpp binaries installer

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help              Show this help
    -v, --version VER       Version to install (default: latest)
    -d, --dir DIR           Installation directory (default: $DEFAULT_INSTALL_DIR)
    -n, --dry-run           Show what will be installed without installing
    -u, --update            Update existing binaries (alias: --force, --upgrade)
    --check-only            Check available versions and exit
    --install               Install this script to ~/.local/bin/llama-installer

AUTO-UPDATE (only for locally installed script):
    --auto-update hourly    Setup automatic updates every hour
    --auto-update daily     Setup automatic updates daily
    --auto-update-enable    Enable auto-update service
    --auto-update-disable   Disable auto-update service
    --auto-update-status    Show auto-update status
    --auto-update-logs      Show auto-update logs
    --auto-update-remove    Remove auto-update configuration
    --auto-update-check     Run update check now

EXAMPLES:
    $SCRIPT_NAME                    # Install latest version
    $SCRIPT_NAME -v b7411           # Install specific version
    $SCRIPT_NAME -n                 # Check what will be installed
    $SCRIPT_NAME -d /opt/bin        # Install in different directory
    $SCRIPT_NAME --install          # Install this script globally
    $SCRIPT_NAME --auto-update hourly   # Setup hourly updates (local only)

EOF
}

# Dependency check function
check_dependencies() {
    local deps=("curl" "tar" "sha256sum" "uname")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        log_info "Install them using:"
        case "$OSTYPE" in
            linux*)
                log_info "  Ubuntu/Debian: sudo apt install ${missing[*]}"
                log_info "  Fedora/RHEL: sudo dnf install ${missing[*]}"
                log_info "  Arch: sudo pacman -S ${missing[*]}"
                ;;
            darwin*)
                log_info "  macOS: brew install ${missing[*]}"
                ;;
            cygwin*|msys*|mingw*)
                log_info "  Windows: Install via Chocolatey or Git Bash"
                ;;
        esac
        exit 1
    fi
}

# Function to detect operating system
detect_os() {
    local os=""
    local arch=""
    
    case "$OSTYPE" in
        linux*)
            os="linux"
            if command -v lsb_release &> /dev/null; then
                local distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
                case "$distro" in
                    ubuntu*) os="ubuntu" ;;
                    fedora*) os="fedora" ;;
                    arch*) os="arch" ;;
                    *) os="linux" ;;
                esac
            fi
            ;;
        darwin*)
            os="macos"
            ;;
        cygwin*|msys*|mingw*)
            os="windows"
            ;;
        *)
            log_error "Unsupported operating system: $OSTYPE"
            exit 1
            ;;
    esac
    
    # Architecture detection
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            arch="x64"
            ;;
        arm64|aarch64)
            arch="arm64"
            ;;
        s390x)
            arch="s390x"
            ;;
        *)
            log_error "Unsupported architecture: $arch"
            exit 1
            ;;
    esac
    
    echo "$os-$arch"
}

# Function to check GPU
detect_gpu() {
    local gpu_info=""
    
    case "$OSTYPE" in
        linux*)
            if command -v nvidia-smi &> /dev/null; then
                local cuda_version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits 2>/dev/null | head -1)
                if [ -n "$cuda_version" ]; then
                    gpu_info="cuda"
                fi
            elif command -v rocm-smi &> /dev/null; then
                gpu_info="hip"
            elif command -v vulkaninfo &> /dev/null; then
                gpu_info="vulkan"
            else
                gpu_info="cpu"
            fi
            ;;
        darwin*)
            # Apple Silicon has built-in Metal support
            gpu_info="metal"
            ;;
        cygwin*|msys*|mingw*)
            if command -v nvidia-smi &> /dev/null; then
                gpu_info="cuda"
            else
                gpu_info="cpu"
            fi
            ;;
        *)
            gpu_info="cpu"
            ;;
    esac
    
    echo "$gpu_info"
}

# Function to download release list from GitHub
fetch_releases() {
    local url="${GITHUB_API_URL}/repos/${REPO_OWNER}/${REPO_NAME}/releases"
    
    if [ "$VERSION" = "latest" ]; then
        url="${url}/latest"
    else
        # Get specific version tag
        url="${GITHUB_API_URL}/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${VERSION}"
    fi
    
    # Use printf to avoid adding newlines that break JSON parsing
    local response
    response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$url")
    
    if [ $? -ne 0 ]; then
        echo "Failed to download information from GitHub" >&2
        exit 1
    fi
    
    # Output the JSON directly
    printf "%s" "$response"
}

# Function to parse available assets
parse_assets() {
    local releases_json="$1"
    local system_info="$2"
    local gpu_type="$3"
    local version="$4"
    
    # Parse JSON and find matching assets
    local os=""
    local arch=""
    
    # Extract OS and architecture from system_info
    IFS='-' read -r os arch <<< "$system_info"
    
    # Map OS names to match GitHub asset naming
    case "$os" in
        "linux")
            os="ubuntu"
            ;;
        "macos")
            os="macos"
            ;;
        "windows")
            os="win"
            ;;
    esac
    
    # Determine file extension
    local extension="tar.gz"
    case "$os" in
        "win")
            extension="zip"
            ;;
    esac
    
    # Try to find the best matching asset
    local best_match=""
    local fallback_match=""
    
    # First, try to find a GPU-specific version
    case "$gpu_type" in
        "cuda")
            # For NVIDIA, try specific CUDA versions first
            best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                | select(.name | contains("cuda-12.4") or contains("cuda-13.1")) | .name' | head -1)
            
            if [ -z "$best_match" ]; then
                best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                    '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                    | select(.name | contains("cuda")) | .name' | head -1)
            fi
            ;;
        "hip")
            best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                | select(.name | contains("hip")) | .name' | head -1)
            ;;
        "vulkan")
            best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                | select(.name | contains("vulkan")) | .name' | head -1)
            ;;
        "metal")
            best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                | select(.name | contains("metal")) | .name' | head -1)
            ;;
        "cpu"|*)
            # Default to CPU version
            best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
                '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) 
                | select(.name | contains("cpu") or (contains($os) and contains($arch) and contains($ext) and (contains("ubuntu") or contains("macos")))) | .name' | head -1)
            ;;
    esac
    
    # If no GPU-specific version found, try any matching version
    if [ -z "$best_match" ]; then
        best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" --arg ext "$extension" \
            '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch) and contains($ext)) | .name' | head -1)
    fi
    
    # If still nothing, try just OS + arch (for Linux variants)
    if [ -z "$best_match" ]; then
        best_match=$(echo "$releases_json" | jq -r --arg os "$os" --arg arch "$arch" \
            '.assets[] | select(.name | contains("bin") and contains($os) and contains($arch)) | .name' | head -1)
    fi
    
    # Fallback to any binary for this OS
    if [ -z "$best_match" ]; then
        best_match=$(echo "$releases_json" | jq -r --arg os "$os" \
            '.assets[] | select(.name | contains("bin") and contains($os)) | .name' | head -1)
    fi
    
    if [ -z "$best_match" ]; then
        return 1
    fi
    
    echo "$best_match"
}

# Function to download and install binaries
download_and_install() {
    local asset_name="$1"
    local releases_json="$2"
    local version="$3"
    local install_dir="$4"
    
    log_info "Downloading archive: $asset_name"
    
    # Get download URL and SHA256
    local download_url=$(echo "$releases_json" | jq -r --arg name "$asset_name" \
        '.assets[] | select(.name == $name) | .browser_download_url')
    local sha256=$(echo "$releases_json" | jq -r --arg name "$asset_name" \
        '.assets[] | select(.name == $name) | .digest' | sed 's/sha256://')
    
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
        log_error "Cannot get download URL for $asset_name"
        return 1
    fi
    
    if [ -z "$sha256" ]; then
        log_warning "No SHA256 checksum found for $asset_name"
    fi
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local archive_file="$temp_dir/$asset_name"
    
    log_info "Downloading from $download_url"
    
    # Download the archive
    if ! curl -L -o "$archive_file" "$download_url"; then
        log_error "Error downloading archive"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # Verify checksum if available
    if [ -n "$sha256" ]; then
        log_info "Verifying checksum..."
        local computed_sha256=$(sha256sum "$archive_file" | cut -d' ' -f1)
        if [ "$computed_sha256" != "$sha256" ]; then
            log_error "Checksum mismatch! Expected: $sha256, Got: $computed_sha256"
            rm -rf "$temp_dir"
            return 1
        fi
        log_success "Checksum verified correctly"
    fi
    
    # Create install directory
    mkdir -p "$install_dir"
    
    # Extract archive
    log_info "Extracting archive to $install_dir"
    case "$asset_name" in
        *.tar.gz)
            tar -xzf "$archive_file" -C "$install_dir" --strip-components=1 2>/dev/null || {
                # Try extracting to temp first, then moving contents
                tar -xzf "$archive_file" -C "$temp_dir"
                find "$temp_dir" -name "llama-cli" -o -name "llama-server" | while read -r file; do
                    cp "$file" "$install_dir/"
                    chmod +x "$install_dir/$(basename "$file")"
                done
            }
            ;;
        *.zip)
            unzip -q "$archive_file" -d "$temp_dir"
            find "$temp_dir" -name "llama-cli" -o -name "llama-server" | while read -r file; do
                cp "$file" "$install_dir/"
                chmod +x "$install_dir/$(basename "$file")"
            done
            ;;
        *)
            log_error "Unsupported archive format: $asset_name"
            rm -rf "$temp_dir"
            return 1
            ;;
    esac
    
    # Clean up
    rm -rf "$temp_dir"
    
    log_success "Binaries installed in $install_dir"
}

# Function to add to PATH
setup_path() {
    local install_dir="$1"
    
    # Check if already in PATH
    if echo "$PATH" | grep -q "$install_dir"; then
        log_info "Directory $install_dir is already in PATH"
        return 0
    fi
    
    log_info "Adding $install_dir to PATH..."
    
    # For bash
    local bashrc="$HOME/.bashrc"
    local zshrc="$HOME/.zshrc"
    
    if [ -f "$bashrc" ]; then
        if ! grep -q "export PATH=\"$install_dir:\$PATH\"" "$bashrc"; then
            echo "" >> "$bashrc"
            echo "# Added by $SCRIPT_NAME" >> "$bashrc"
            echo "export PATH=\"$install_dir:\$PATH\"" >> "$bashrc"
            log_success "Dodano do $bashrc"
        fi
    fi
    
    if [ -f "$zshrc" ]; then
        if ! grep -q "export PATH=\"$install_dir:\$PATH\"" "$zshrc"; then
            echo "" >> "$zshrc"
            echo "# Added by $SCRIPT_NAME" >> "$zshrc"
            echo "export PATH=\"$install_dir:\$PATH\"" >> "$zshrc"
            log_success "Dodano do $zshrc"
        fi
    fi
    
    log_warning "Run 'source ~/.bashrc' or 'source ~/.zshrc' to update PATH in current session"
}

# Function to install the script itself
self_install() {
    local install_target="$HOME/.local/bin/llama-installer"
    local install_dir="$(dirname "$install_target")"
    
    # Determine the source URL based on current execution context
    local script_url
    if [[ "${BASH_SOURCE[0]:-${0}}" == *"raw.githubusercontent.com"* ]]; then
        # Running from GitHub, use the same URL but with master branch
        script_url="https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh"
    else
        # Running locally, provide instructions
        script_url="https://raw.githubusercontent.com/Rybens92/llama-installer/refs/heads/master/llama-installer.sh"
    fi
    
    log_info "Installing $SCRIPT_NAME to $install_target..."
    
    # Create installation directory if it doesn't exist
    if [ ! -d "$install_dir" ]; then
        log_info "Creating directory: $install_dir"
        mkdir -p "$install_dir"
    fi
    
    # Check if file already exists and inform user
    if [ -f "$install_target" ]; then
        log_info "Overwriting existing installation: $install_target"
    fi
    
    # Download the script
    log_info "Downloading from: $script_url"
    if ! curl -fsSL "$script_url" -o "$install_target"; then
        log_error "Failed to download script from $script_url"
        exit 1
    fi
    
    # Make the script executable
    log_info "Setting executable permissions..."
    chmod +x "$install_target"
    
    # Setup PATH for future sessions
    log_info "Setting up PATH..."
    setup_path "$install_dir"
    
    # Verify installation
    if [ -x "$install_target" ]; then
        log_success "Installation completed successfully!"
        log_info "Script installed at: $install_target"
        
        # Test if it works
        log_info "Testing installation..."
        if "$install_target" --help >/dev/null 2>&1; then
            log_success "Installation verified!"
        else
            log_warning "Installation completed but verification failed"
        fi
        
        log_info ""
        log_info "Usage:"
        log_info "  $install_target --help      # Show help"
        log_info "  $install_target -n          # Dry run"
        log_info "  $install_target             # Install latest llama.cpp"
        log_info ""
        log_info "For immediate use in current session, run:"
        log_info "  source ~/.bashrc  # or source ~/.zshrc"
        log_info "Or add to PATH manually:"
        log_info "  export PATH=\"$install_dir:\$PATH\""
    else
        log_error "Installation failed - script is not executable"
        exit 1
    fi
}

# Function to check installed llama.cpp version
check_llama_version() {
    local llama_server_path="$1"
    
    # Check if file exists and is executable
    if [ ! -x "$llama_server_path" ]; then
        return 1  # Not installed or not executable
    fi
    
    # Try to get version from --version flag (output goes to stderr)
    local version_output
    if version_output=$("$llama_server_path" --version 2>&1); then
        # Extract version number (7411 from "version: 7411 (165caaf5f)")
        local installed_version=$(echo "$version_output" | grep "version:" | awk '{print $2}' | cut -d'(' -f1)
        if [ -n "$installed_version" ]; then
            echo "$installed_version"
            return 0
        fi
    fi
    
    # Fallback: if --version doesn't work, try --help to check if binary is functional
    if "$llama_server_path" --help >/dev/null 2>&1; then
        # Binary works but --version failed - this might be an older version or different output format
        log_warning "llama-server works but version format could not be parsed"
        # Return a special value to indicate binary exists but version unknown
        echo "unknown"
        return 0
    fi
    
    # If neither --version nor --help works, assume binary is broken or incomplete
    log_warning "llama-server binary exists but doesn't work properly"
    return 1
}

# Function to get latest available version from GitHub
get_latest_version() {
    local latest_tag
    latest_tag=$(curl -s "${GITHUB_API_URL}/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | jq -r '.tag_name')
    
    if [ -n "$latest_tag" ] && [ "$latest_tag" != "null" ]; then
        # Extract number from tag (b7426 -> 7426)
        echo "$latest_tag" | sed 's/^b//'
        return 0
    fi
    
    return 1
}

# ===== AUTO-UPDATE FUNCTIONS =====

# Check if script is locally installed
is_locally_installed() {
    local script_path="$(realpath "$0")"
    
    # Check typical local installation locations
    if [[ "$script_path" == /usr/local/bin/* ]] || 
       [[ "$script_path" == /usr/bin/* ]] || 
       [[ "$script_path" == ~/.local/bin/* ]]; then
        return 0  # ✅ Locally installed
    fi
    
    # Check if we can write to the script directory (likely local)
    if [ -w "$(dirname "$script_path")" ]; then
        return 0  # ✅ Probably local
    fi
    
    return 1  # ❌ Probably curl pipe
}

# Require local installation for auto-update features
require_local_install() {
    if ! is_locally_installed; then
        log_error "Auto-update is only available for locally installed $SCRIPT_NAME"
        log_info "Please install locally first:"
        log_info "  curl -fsSL https://raw.githubusercontent.com/Rybens92/llama-installer/0539ad5/llama-installer.sh | bash -s -- --install"
        exit 1
    fi
}

# Create auto-update configuration directory
create_auto_update_config_dir() {
    if [ ! -d "$AUTO_UPDATE_CONFIG_DIR" ]; then
        mkdir -p "$AUTO_UPDATE_CONFIG_DIR"
        log_info "Created configuration directory: $AUTO_UPDATE_CONFIG_DIR"
    fi
}

# Create auto-update configuration file
create_auto_update_config() {
    local interval="$1"  # hourly or daily
    local script_path="$(realpath "$0")"
    
    create_auto_update_config_dir
    
    cat > "$AUTO_UPDATE_CONFIG_FILE" << EOF
# Auto-update configuration for llama-installer
INTERVAL="$interval"
SCRIPT_PATH="$script_path"
LAST_CHECK=""
LAST_VERSION=""
ENABLED="true"
TIMER_NAME="$AUTO_UPDATE_TIMER_NAME"
SERVICE_NAME="$AUTO_UPDATE_SERVICE_NAME"
EOF
    
    log_success "Created auto-update configuration: $AUTO_UPDATE_CONFIG_FILE"
}

# Create systemd service file
create_systemd_service_file() {
    local script_path="$(realpath "$0")"
    
    local service_dir="$HOME/.config/systemd/user"
    if [ ! -d "$service_dir" ]; then
        mkdir -p "$service_dir"
    fi
    
    cat > "$service_dir/$AUTO_UPDATE_SERVICE_NAME" << EOF
[Unit]
Description=Llama.cpp Auto-Update Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=$script_path -u
WorkingDirectory=$HOME
User=$USER
Environment=DISPLAY=:0
StandardOutput=append:$AUTO_UPDATE_LOG_FILE
StandardError=append:$AUTO_UPDATE_LOG_FILE

[Install]
WantedBy=multi-user.target
EOF
    
    log_success "Created systemd service file: $service_dir/$AUTO_UPDATE_SERVICE_NAME"
}

# Create systemd timer file
create_systemd_timer_file() {
    local interval="$1"  # hourly or daily
    
    local service_dir="$HOME/.config/systemd/user"
    if [ ! -d "$service_dir" ]; then
        mkdir -p "$service_dir"
    fi
    
    # Determine OnCalendar based on interval
    local calendar_spec=""
    case "$interval" in
        hourly)
            calendar_spec="hourly"
            ;;
        daily)
            calendar_spec="daily"
            ;;
        *)
            log_error "Invalid interval: $interval"
            exit 1
            ;;
    esac
    
    cat > "$service_dir/$AUTO_UPDATE_TIMER_NAME" << EOF
[Unit]
Description=Llama.cpp Auto-Update Timer ($interval)
Requires=$AUTO_UPDATE_SERVICE_NAME

[Timer]
OnCalendar=$calendar_spec
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF
    
    log_success "Created systemd timer file: $service_dir/$AUTO_UPDATE_TIMER_NAME"
}

# Setup auto-update (main function)
setup_auto_update() {
    local interval="$1"  # hourly or daily
    
    log_info "Setting up $interval auto-update for llama.cpp..."
    
    # Create configuration
    create_auto_update_config "$interval"
    
    # Create systemd files
    create_systemd_service_file
    create_systemd_timer_file "$interval"
    
    # Reload systemd daemon
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload
        log_success "Systemd daemon reloaded"
    else
        log_warning "systemctl not found - systemd timers not available"
        setup_cron_fallback "$interval"
        return 0
    fi
    
    # Enable and start timer
    enable_auto_update
}

# Enable auto-update timer
enable_auto_update() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user enable "$AUTO_UPDATE_TIMER_NAME"
        systemctl --user start "$AUTO_UPDATE_TIMER_NAME"
        log_success "Auto-update timer enabled and started"
        show_auto_update_status
    else
        log_error "systemctl not found - cannot enable systemd timer"
        exit 1
    fi
}

# Disable auto-update timer
disable_auto_update() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user stop "$AUTO_UPDATE_TIMER_NAME" 2>/dev/null || true
        systemctl --user disable "$AUTO_UPDATE_TIMER_NAME" 2>/dev/null || true
        log_success "Auto-update timer disabled"
    else
        log_warning "systemctl not found"
    fi
}

# Show auto-update status
show_auto_update_status() {
    echo
    log_info "=== Auto-Update Status ==="
    
    if [ -f "$AUTO_UPDATE_CONFIG_FILE" ]; then
        source "$AUTO_UPDATE_CONFIG_FILE"
        echo "Interval: $INTERVAL"
        echo "Script path: $SCRIPT_PATH"
        echo "Enabled: $ENABLED"
        echo "Last check: ${LAST_CHECK:-Never}"
        echo "Last version: ${LAST_VERSION:-Unknown}"
    else
        echo "No configuration found"
    fi
    
    if command -v systemctl >/dev/null 2>&1; then
        echo
        echo "=== Systemd Timer Status ==="
        systemctl --user status "$AUTO_UPDATE_TIMER_NAME" --no-pager || true
    else
        echo "systemctl not available"
    fi
}

# Show auto-update logs
show_auto_update_logs() {
    if command -v journalctl >/dev/null 2>&1; then
        log_info "=== Systemd Journal Logs ==="
        journalctl --user -u "$AUTO_UPDATE_SERVICE_NAME" --no-pager -n 50 || true
    else
        if [ -f "$AUTO_UPDATE_LOG_FILE" ]; then
            log_info "=== Log File ==="
            tail -n 50 "$AUTO_UPDATE_LOG_FILE"
        else
            log_info "No logs available"
        fi
    fi
}

# Update auto-update configuration
update_auto_update_config() {
    local new_version="$1"
    
    # Only update if configuration exists
    if [ ! -f "$AUTO_UPDATE_CONFIG_FILE" ]; then
        return 0
    fi
    
    # Get current timestamp
    local current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Update config file
    sed -i "s/LAST_CHECK=.*/LAST_CHECK=\"$current_time\"/" "$AUTO_UPDATE_CONFIG_FILE"
    sed -i "s/LAST_VERSION=.*/LAST_VERSION=\"$new_version\"/" "$AUTO_UPDATE_CONFIG_FILE"
}

# Remove auto-update configuration
remove_auto_update() {
    log_warning "This will remove all auto-update configuration and stop the timer."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        exit 0
    fi
    
    # Disable timer
    disable_auto_update
    
    # Remove systemd files
    local service_dir="$HOME/.config/systemd/user"
    rm -f "$service_dir/$AUTO_UPDATE_SERVICE_NAME" 2>/dev/null || true
    rm -f "$service_dir/$AUTO_UPDATE_TIMER_NAME" 2>/dev/null || true
    
    # Reload systemd daemon
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload
    fi
    
    # Remove configuration
    rm -rf "$AUTO_UPDATE_CONFIG_DIR" 2>/dev/null || true
    
    log_success "Auto-update configuration removed"
}

# Run auto-update check manually
run_auto_update_check() {
    log_info "Running manual update check..."
    
    # Run the update
    if "$0" -u; then
        log_success "Update check completed"
    else
        log_warning "Update check encountered issues"
    fi
}

# Setup cron fallback for systems without systemd
setup_cron_fallback() {
    local interval="$1"  # hourly or daily
    
    log_warning "systemd not available - setting up cron fallback"
    
    # Determine cron schedule
    local cron_schedule=""
    case "$interval" in
        hourly)
            cron_schedule="0 * * * *"  # Every hour
            ;;
        daily)
            cron_schedule="0 0 * * *"  # Every day at midnight
            ;;
    esac
    
    # Create cron job
    local cron_cmd="$0 -u"
    (crontab -l 2>/dev/null | grep -v "$cron_cmd"; echo "$cron_schedule $cron_cmd") | crontab -
    
    log_success "Created cron job for $interval updates"
    log_info "Schedule: $cron_schedule"
    log_info "Command: $cron_cmd"
}

# Main function
main() {
    local args=()
    
    # Argument parsing
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                VERSION="$2"
                shift 2
                ;;
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -u|--update|--upgrade|--force)
                UPDATE=true
                shift
                ;;
            --check-only)
                # TODO: Implement checking available versions
                exit 0
                ;;
            --install|--self-install)
                self_install
                exit 0
                ;;
            --auto-update)
                if [ -z "${2:-}" ] || [[ "$2" != "hourly" && "$2" != "daily" ]]; then
                    log_error "Usage: $SCRIPT_NAME --auto-update {hourly|daily}"
                    exit 1
                fi
                require_local_install
                setup_auto_update "$2"
                shift 2
                exit 0
                ;;
            --auto-update-enable)
                require_local_install
                enable_auto_update
                exit 0
                ;;
            --auto-update-disable)
                require_local_install
                disable_auto_update
                exit 0
                ;;
            --auto-update-status)
                require_local_install
                show_auto_update_status
                exit 0
                ;;
            --auto-update-logs)
                require_local_install
                show_auto_update_logs
                exit 0
                ;;
            --auto-update-remove)
                require_local_install
                remove_auto_update
                exit 0
                ;;
            --auto-update-check)
                require_local_install
                run_auto_update_check
                exit 0
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    # Check dependencies
    check_dependencies
    
    # System detection
    local system_info=$(detect_os)
    local gpu_type=$(detect_gpu)
    
    log_info "Detected system: $system_info"
    log_info "Detected GPU: $gpu_type"
    log_info "Installation directory: $INSTALL_DIR"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - no installation will be performed"
        
        # Test GitHub API connection first
        log_info "Downloading release information from GitHub..."
        local test_response=$(fetch_releases)
        if echo "$test_response" | jq -e . >/dev/null 2>&1; then
            log_success "GitHub API connection works"
            local tag_name=$(echo "$test_response" | jq -r '.tag_name')
            local asset_name=$(parse_assets "$test_response" "$system_info" "$gpu_type" "$VERSION")
            
            # Special warning for CUDA GPU users when Vulkan is selected as fallback (dry-run mode)
            if [ "$gpu_type" = "cuda" ] && [[ "$asset_name" == *"vulkan"* ]]; then
                log_warning "CUDA GPU detected, but no CUDA builds available for $system_info"
                log_info "Using Vulkan as best alternative (supports CUDA GPU)"
            fi
            
            if [ -n "$asset_name" ]; then
                # Clean up any color codes from the asset name
                local clean_asset_name=$(echo "$asset_name" | sed 's/\x1b\[[0-9;]*m//g')
                local download_url=$(echo "$test_response" | jq -r --arg name "$clean_asset_name" \
                    '.assets[] | select(.name == $name) | .browser_download_url')
                log_info "Will be downloaded: $clean_asset_name"
                log_info "URL: $download_url"
                log_info "Version: $tag_name"
            else
                log_error "No appropriate archive found"
                exit 1
            fi
        else
            log_error "Cannot establish connection to GitHub API"
            exit 1
        fi
        exit 0
    fi
    
    # Fetch releases using the fetch_releases function
    log_info "Downloading release information from GitHub..."
    local releases_json=$(fetch_releases)
    local tag_name=$(echo "$releases_json" | jq -r '.tag_name')
    
    log_info "Version: $tag_name"
    
    # Check if already installed (only skip if using latest version and no specific version requested)
    if [ "$UPDATE" = false ] && [ "$VERSION" = "latest" ] && [ -d "$INSTALL_DIR" ]; then
        if [ -f "$INSTALL_DIR/llama-cli" ] || [ -f "$INSTALL_DIR/llama-server" ]; then
            log_info "llama.cpp binaries already exist in $INSTALL_DIR"
            log_info "Use --update to update binaries or specify a version with -v"
            
            # Test if binaries work
            if [ -x "$INSTALL_DIR/llama-cli" ]; then
                log_info "Testing existing binaries..."
                if "$INSTALL_DIR/llama-cli" --help >/dev/null 2>&1; then
                    log_success "Existing binaries work correctly"
                    log_info "To install a specific version, use: $SCRIPT_NAME -v <version>"
                    exit 0
                else
                    log_warning "Existing binaries don't work - performing reinstallation"
                fi
            fi
        fi
    fi
    
    # Handle --update flag with version checking
    if [ "$UPDATE" = true ]; then
        local llama_server="$INSTALL_DIR/llama-server"
        local installed_version
        local latest_version
        
        # Check installed version
        if installed_version=$(check_llama_version "$llama_server"); then
            # Handle special case where version could not be determined but binary exists
            if [ "$installed_version" = "unknown" ]; then
                log_warning "llama.cpp binary exists but version could not be determined"
                log_info "Proceeding with update to ensure compatibility"
            else
                log_info "Current installed version: $installed_version"
                
                # Check latest available version
                if latest_version=$(get_latest_version); then
                    log_info "Latest available version: $latest_version"
                    
                    # Compare versions
                    if [ "$installed_version" -ge "$latest_version" ] 2>/dev/null; then
                        log_success "You already have the latest version of llama.cpp ($installed_version)"
                        log_info "No update needed."
                        
                        # Update auto-update configuration even when no update is needed
                        update_auto_update_config "$latest_version"
                        exit 0
                    else
                        log_info "New version available: $latest_version (current: $installed_version)"
                    fi
                else
                    log_warning "Could not check latest version - proceeding with update"
                fi
            fi
        else
            log_info "llama.cpp not found or not working properly - installing fresh"
        fi
    fi
    
    # Parse and select appropriate asset
    local asset_name=$(parse_assets "$releases_json" "$system_info" "$gpu_type" "$VERSION")
    
    # Special warning for CUDA GPU users when Vulkan is selected as fallback
    if [ "$gpu_type" = "cuda" ] && [[ "$asset_name" == *"vulkan"* ]]; then
        log_warning "CUDA GPU detected, but no CUDA builds available for $system_info"
        log_info "Using Vulkan as best alternative (supports CUDA GPU)"
    fi
    
    if [ -z "$asset_name" ]; then
        log_error "Cannot find appropriate archive"
        exit 1
    fi
    
    log_success "Selected archive: $asset_name"
    
    # Download and install
    if ! download_and_install "$asset_name" "$releases_json" "$tag_name" "$INSTALL_DIR"; then
        log_error "Installation error"
        exit 1
    fi
    
    # Setup PATH
    setup_path "$INSTALL_DIR"
    
    # Verify installation
    if [ -x "$INSTALL_DIR/llama-cli" ]; then
        log_success "Installation completed successfully!"
        log_info "You can now use:"
        log_info "  llama-cli --help"
        log_info "  llama-server --help"
        log_warning "Remember to run 'source ~/.bashrc' to update PATH"
        
        # Update auto-update configuration if exists
        update_auto_update_config "$tag_name"
    else
        log_error "Installation completed, but binaries are not available"
        exit 1
    fi
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "$@"
fi