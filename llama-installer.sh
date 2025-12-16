#!/bin/bash

# llama-installer.sh - Automatic installer for llama.cpp binaries
# Version: 1.0.0
# Author: OpenHands
# Description: Downloads and installs the latest llama.cpp binaries from GitHub releases

set -euo pipefail

# Configuration
readonly SCRIPT_NAME="llama-installer"
readonly REPO_OWNER="ggml-org"
readonly REPO_NAME="llama.cpp"
readonly DEFAULT_INSTALL_DIR="$HOME/.local/bin"
readonly GITHUB_API_URL="https://api.github.com"

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

EXAMPLES:
    $SCRIPT_NAME                    # Install latest version
    $SCRIPT_NAME -v b7411           # Install specific version
    $SCRIPT_NAME -n                 # Check what will be installed
    $SCRIPT_NAME -d /opt/bin        # Install in different directory

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
    fi
    
    log_info "Downloading release information from GitHub..."
    
    # Use printf to avoid adding newlines that break JSON parsing
    local response
    response=$(curl -s -H "Accept: application/vnd.github.v3+json" "$url")
    
    if [ $? -ne 0 ]; then
        log_error "Failed to download information from GitHub"
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
        local test_response=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest")
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
    
    # Fetch releases
    log_info "Downloading release information..."
    local releases_json=$(curl -s -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest")
    local tag_name=$(echo "$releases_json" | jq -r '.tag_name')
    
    log_info "Latest version: $tag_name"
    
    # Check if already installed
    if [ "$UPDATE" = false ] && [ -d "$INSTALL_DIR" ]; then
        if [ -f "$INSTALL_DIR/llama-cli" ] || [ -f "$INSTALL_DIR/llama-server" ]; then
            log_info "llama.cpp binaries already exist in $INSTALL_DIR"
            log_info "Use --update to update binaries"
            
            # Test if binaries work
            if [ -x "$INSTALL_DIR/llama-cli" ]; then
                log_info "Testing existing binaries..."
                if "$INSTALL_DIR/llama-cli" --help >/dev/null 2>&1; then
                    log_success "Existing binaries work correctly"
                    exit 0
                else
                    log_warning "Existing binaries don't work - performing reinstallation"
                fi
            fi
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
    else
        log_error "Installation completed, but binaries are not available"
        exit 1
    fi
}

# Check if script is run directly
if [[ "${BASH_SOURCE[0]:-${0}}" == "${0}" ]]; then
    main "$@"
fi