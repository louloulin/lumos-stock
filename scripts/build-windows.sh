#!/bin/bash

set -e  # Exit on error

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Start running the script..."
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"

cd "$PROJECT_ROOT"

# Check if wails is installed
if ! command -v wails &> /dev/null; then
    echo "Error: wails is not installed"
    echo "Please install wails first: https://wails.io/docs/gettingstarted/installation"
    exit 1
fi

# Detect current OS and architecture
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"
echo "Current OS: $OS_TYPE"
echo "Current Architecture: $ARCH_TYPE"

# Check cross-compilation scenario
CROSS_COMPILE=false
if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "Warning: Cross-compiling for Windows from macOS is complex and may fail"
    echo ""
    echo "Recommended solutions:"
    echo "1. Use GitHub Actions (already configured in .github/workflows/main.yml)"
    echo "   git tag v1.0.0-dev && git push origin v1.0.0-dev"
    echo ""
    echo "2. Build on native Windows machine or VM"
    echo ""
    echo "3. Use Docker cross-compilation environment"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled"
        exit 0
    fi
    CROSS_COMPILE=true
fi

echo "Start building the app for windows/amd64 platform..."

# Set cross-compilation environment variables if needed
if [ "$CROSS_COMPILE" = true ]; then
    echo "Setting up cross-compilation environment..."
    export GOOS=windows
    export GOARCH=amd64
    export CGO_ENABLED=1
    # Note: This will likely fail without proper cross-compilation toolchain
fi

wails build --clean --platform windows/amd64

echo "Build completed successfully!"
echo "Output directory: $PROJECT_ROOT/build/bin"
