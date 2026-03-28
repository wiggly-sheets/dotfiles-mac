#!/bin/bash
# ============================================================================
# Enable Touch ID for sudo Commands (macOS only)
# Allows fingerprint authentication instead of password for sudo in terminals
# Note: This script only works on macOS and will exit on other systems
# ============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() { echo -e "${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

# ============================================================================
# TOUCH ID SETUP
# ============================================================================
enable_touchid() {
  print_status "Enabling Touch ID for sudo commands..."

  # Check if Touch ID is already enabled
  if [[ -f /etc/pam.d/sudo ]]; then
    if grep -q "pam_tid.so" /etc/pam.d/sudo; then
      print_success "Touch ID is already enabled for sudo"
      return 0
    fi
  fi

  # Create sudo file with Touch ID support
  # This file persists across macOS updates (sudo file doesn't)
  print_status "Creating /etc/pam.d/sudo..."
  sudo sh -c 'echo "# Touch ID support for sudo
auth       sufficient     pam_tid.so" > /etc/pam.d/sudo'

  print_success "Touch ID enabled for sudo commands!"
  echo ""
  echo "You can now use your fingerprint for sudo authentication in:"
  echo "  • Ghostty"
  echo "  • iTerm2"
  echo "  • Terminal.app"
  echo "  • Any other terminal emulator"
  echo ""
  print_warning "Note: You may need to restart your terminal for changes to take effect"
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║           🔐 Touch ID for sudo Setup                          ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  # Check if running on macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    print_error "This script is only for macOS (Touch ID is not available on Linux)"
    print_status "If you're on Arch Linux, this feature will be skipped automatically"
    exit 1
  fi

  # Check if Touch ID is available
  if ! bioutil -r -s &>/dev/null; then
    print_warning "Touch ID may not be available on this Mac"
    print_warning "Continuing anyway..."
  fi

  enable_touchid

  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Try it out:"
  echo "  1. Close and reopen your terminal"
  echo "  2. Run any sudo command (e.g., 'sudo ls')"
  echo "  3. Touch your fingerprint sensor when prompted"
  echo ""
}

main "$@"
