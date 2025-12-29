#!/bin/bash
#
# Install script for tilt-logs
# https://github.com/ChrisMasterton/tilt-log-cli
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ChrisMasterton/tilt-log-cli/main/install.sh | bash
#   or
#   ./install.sh [--from-source]
#

set -e

APP_NAME="tilt-logs"
REPO="ChrisMasterton/tilt-log-cli"
INSTALL_DIR="/usr/local/bin"
VERSION="v0.1.6"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    echo -e "${BLUE}==>${NC} $1"
}

success() {
    echo -e "${GREEN}==>${NC} $1"
}

warn() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

error() {
    echo -e "${RED}Error:${NC} $1" >&2
    exit 1
}

# Detect OS and architecture
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case "$OS" in
        darwin)
            case "$ARCH" in
                arm64|aarch64)
                    PLATFORM="aarch64-apple-darwin"
                    ;;
                x86_64)
                    PLATFORM="x86_64-apple-darwin"
                    ;;
                *)
                    error "Unsupported architecture: $ARCH"
                    ;;
            esac
            ;;
        linux)
            error "Linux is not yet supported. Please build from source."
            ;;
        *)
            error "Unsupported operating system: $OS"
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get the latest version from GitHub
get_latest_version() {
    if command_exists curl; then
        curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command_exists wget; then
        wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | \
            grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    fi
}

# Install from prebuilt binary
install_binary() {
    info "Installing $APP_NAME $VERSION..."

    detect_platform

    TARBALL="${APP_NAME}-${PLATFORM}.tar.gz"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"

    info "Detected platform: $PLATFORM"
    info "Downloading from: $DOWNLOAD_URL"

    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap "rm -rf $TMP_DIR" EXIT

    # Download
    if command_exists curl; then
        curl -fsSL "$DOWNLOAD_URL" -o "$TMP_DIR/$TARBALL" || error "Download failed. Check if version $VERSION exists."
    elif command_exists wget; then
        wget -q "$DOWNLOAD_URL" -O "$TMP_DIR/$TARBALL" || error "Download failed. Check if version $VERSION exists."
    else
        error "Neither curl nor wget found. Please install one of them."
    fi

    # Extract
    info "Extracting..."
    tar -xzf "$TMP_DIR/$TARBALL" -C "$TMP_DIR"

    # Install
    info "Installing to $INSTALL_DIR..."
    if [ -w "$INSTALL_DIR" ]; then
        cp "$TMP_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME"
        chmod +x "$INSTALL_DIR/$APP_NAME"
    else
        warn "Need sudo to install to $INSTALL_DIR"
        sudo cp "$TMP_DIR/$APP_NAME" "$INSTALL_DIR/$APP_NAME"
        sudo chmod +x "$INSTALL_DIR/$APP_NAME"
    fi

    success "$APP_NAME $VERSION installed successfully!"
}

# Install from source
install_from_source() {
    info "Building $APP_NAME from source..."

    # Check for Rust
    if ! command_exists cargo; then
        error "Rust is not installed. Install it from https://rustup.rs/ or run:\n  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi

    # Check if we're in the repo directory
    if [ -f "Cargo.toml" ] && grep -q "name = \"$APP_NAME\"" Cargo.toml; then
        info "Building in current directory..."
    else
        # Clone the repo
        if ! command_exists git; then
            error "Git is not installed. Please install git first."
        fi

        TMP_DIR=$(mktemp -d)
        trap "rm -rf $TMP_DIR" EXIT

        info "Cloning repository..."
        git clone "https://github.com/${REPO}.git" "$TMP_DIR/repo"
        cd "$TMP_DIR/repo"
    fi

    # Build
    info "Compiling (this may take a moment)..."
    cargo build --release

    # Install
    info "Installing to $INSTALL_DIR..."
    if [ -w "$INSTALL_DIR" ]; then
        cp "target/release/$APP_NAME" "$INSTALL_DIR/$APP_NAME"
        chmod +x "$INSTALL_DIR/$APP_NAME"
    else
        warn "Need sudo to install to $INSTALL_DIR"
        sudo cp "target/release/$APP_NAME" "$INSTALL_DIR/$APP_NAME"
        sudo chmod +x "$INSTALL_DIR/$APP_NAME"
    fi

    success "$APP_NAME installed successfully from source!"
}

# Show usage
show_usage() {
    cat <<EOF
$APP_NAME installer

Usage:
    ./install.sh [OPTIONS]

Options:
    --from-source    Build from source instead of downloading prebuilt binary
    --version VER    Install a specific version (e.g., v0.1.6)
    --help           Show this help message

Installation methods:
    1. Prebuilt binary (default, fastest):
       ./install.sh

    2. Build from source (requires Rust):
       ./install.sh --from-source

    3. Homebrew (if you have a tap set up):
       brew tap ChrisMasterton/homebrew-tap
       brew install $APP_NAME

After installation:
    Make sure Docker is installed and running, then:
        $APP_NAME --list          # List available containers
        $APP_NAME <container>     # View logs
        $APP_NAME <container> -f  # Follow logs

EOF
}

# Main
main() {
    FROM_SOURCE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from-source)
                FROM_SOURCE=true
                shift
                ;;
            --version)
                VERSION="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1\nRun './install.sh --help' for usage."
                ;;
        esac
    done

    echo ""
    echo "  ╔════════════════════════════════════╗"
    echo "  ║       $APP_NAME installer          ║"
    echo "  ╚════════════════════════════════════╝"
    echo ""

    # Try to get latest version
    LATEST=$(get_latest_version)
    if [ -n "$LATEST" ] && [ "$LATEST" != "$VERSION" ]; then
        info "Latest version available: $LATEST (script default: $VERSION)"
        VERSION="$LATEST"
    fi

    if $FROM_SOURCE; then
        install_from_source
    else
        install_binary
    fi

    echo ""
    success "Installation complete!"
    echo ""
    echo "  Verify installation:"
    echo "    $APP_NAME --help"
    echo ""
    echo "  Quick start:"
    echo "    $APP_NAME --list          # List containers"
    echo "    $APP_NAME <name> -f       # Follow logs"
    echo ""

    # Check for Docker
    if ! command_exists docker; then
        warn "Docker is not installed. $APP_NAME requires Docker to function."
    elif ! docker info >/dev/null 2>&1; then
        warn "Docker is not running. Start Docker to use $APP_NAME."
    fi
}

main "$@"
