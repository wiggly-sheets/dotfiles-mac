#!/bin/bash
# ============================================================================
# Dotfiles Setup Script
# Run this after cloning dotfiles repo to set up symlinks and install packages
# Supports: macOS (Homebrew) and Arch Linux (pacman)
# ============================================================================

set -e

DOTFILES_DIR="$HOME/dotfiles"
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
# OS DETECTION
# ============================================================================
detect_os() {
  case "$(uname -s)" in
    Darwin*)
      OS="macos"
      print_status "Detected OS: macOS"
      ;;
    Linux*)
      if [[ -f /etc/arch-release ]]; then
        OS="arch"
        print_status "Detected OS: Arch Linux"
      else
        OS="linux"
        print_status "Detected OS: Linux (generic)"
      fi
      ;;
    *)
      OS="unknown"
      print_warning "Unknown OS: $(uname -s)"
      ;;
  esac
}

# ============================================================================
# HOMEBREW (macOS only)
# ============================================================================
setup_homebrew() {
  if [[ "$OS" != "macos" ]]; then
    print_status "Skipping Homebrew setup (not on macOS)"
    return 0
  fi

  print_status "Setting up Homebrew..."

  if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to path for this session
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  print_success "Homebrew installed"
}

# ============================================================================
# STOW
# ============================================================================
setup_stow() {
  print_status "Setting up GNU Stow..."

  if ! command -v stow &> /dev/null; then
    print_status "Installing GNU Stow via Homebrew..."
    brew install stow
  fi

  print_success "GNU Stow installed"
}

setup_symlinks() {
  print_status "Creating symlinks with stow..."

  # Remove existing manual symlinks if they exist
  if [[ -L "$HOME/.zshrc" ]]; then
    print_status "Removing old manual symlink: ~/.zshrc"
    rm "$HOME/.zshrc"
  fi

  # Backup existing files that aren't symlinks
  if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
    print_warning "Backing up existing ~/.zshrc to ~/.zshrc.bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  fi

  # Use stow to create all symlinks
  cd "$DOTFILES_DIR"
  stow -v .

  print_success "Symlinks created with stow"
}

# ============================================================================
# SKILLS
# ============================================================================
setup_skills() {
  print_status "Linking skills into agent harnesses..."

  mkdir -p "$HOME/.agents" "$HOME/.claude/skills"

  # Universal agent directory points at the dotfiles copy.
  if [[ -e "$HOME/.agents/skills" && ! -L "$HOME/.agents/skills" ]]; then
    print_warning "~/.agents/skills is a real directory; leaving it alone"
  else
    ln -sfn "$DOTFILES_DIR/skills" "$HOME/.agents/skills"
  fi

  # Claude Code gets one symlink per skill.
  local skill dest
  for skill in "$DOTFILES_DIR"/skills/*/; do
    [[ -f "$skill/SKILL.md" ]] || continue
    dest="$HOME/.claude/skills/$(basename "$skill")"
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      print_warning "$dest is not a symlink; leaving it alone"
      continue
    fi
    ln -sfn "../../.agents/skills/$(basename "$skill")" "$dest"
  done

  # Keep the npx skills lock file inside dotfiles so update state syncs too.
  local lock_dir
  if [[ -n "${XDG_STATE_HOME:-}" ]]; then
    lock_dir="$XDG_STATE_HOME/skills"
  else
    lock_dir="$HOME/.agents"
  fi
  mkdir -p "$lock_dir"
  if [[ -f "$lock_dir/.skill-lock.json" && ! -L "$lock_dir/.skill-lock.json" ]]; then
    mv "$lock_dir/.skill-lock.json" "$lock_dir/.skill-lock.json.bak"
    print_warning "Backed up existing skill lock to $lock_dir/.skill-lock.json.bak"
  fi
  ln -sfn "$DOTFILES_DIR/skills/.skill-lock.json" "$lock_dir/.skill-lock.json"

  print_success "Skills linked"
}

# ============================================================================
# PACKAGES
# ============================================================================
install_packages() {
  if [[ "$OS" == "macos" ]]; then
    print_status "Installing packages via Homebrew..."
    brew update
    brew bundle install --cleanup --file="$DOTFILES_DIR/Brewfile"
    brew upgrade
    print_success "All packages installed"
  elif [[ "$OS" == "arch" ]]; then
    print_status "Skipping package installation on Arch Linux"
    print_warning "Note: Install packages manually using pacman/yay on Arch"
    print_warning "Brewfile is macOS-specific"
  else
    print_warning "Unknown package manager for this OS"
    print_warning "Please install packages manually"
  fi
}

# ============================================================================
# TOUCH ID (macOS only)
# ============================================================================
setup_touchid() {
  if [[ "$OS" != "macos" ]]; then
    print_status "Skipping Touch ID setup (macOS only feature)"
    return 0
  fi

  print_status "Setting up Touch ID for sudo..."

  # Check if already enabled
  if [[ -f /etc/pam.d/sudo ]] && grep -q "pam_tid.so" /etc/pam.d/sudo; then
    print_success "Touch ID already enabled for sudo"
    return 0
  fi

  echo ""
  print_warning "Touch ID allows using fingerprint instead of password for sudo commands"
  read -p "Enable Touch ID for sudo? (y/N): " -n 1 -r
  echo ""

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo sh -c 'echo "# Touch ID support for sudo
auth       sufficient     pam_tid.so" > /etc/pam.d/sudo'
    print_success "Touch ID enabled for sudo"
  else
    print_status "Skipping Touch ID setup (you can run scripts/enable-touchid-sudo.sh later)"
  fi
}

# ============================================================================
# MAIN
# ============================================================================
main() {
  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║               🛠️  Dotfiles Setup Script                       ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""

  detect_os
  setup_homebrew
  setup_stow
  setup_symlinks
  setup_skills
  install_packages
  setup_touchid

  echo ""
  print_success "Setup complete! 🎉"
  echo ""
  echo "Next steps:"
  echo "  1. Restart your terminal or run: source ~/.zshrc"
  if [[ "$OS" == "macos" ]]; then
    echo "  2. Run 'bbiu' anytime to update packages"
    echo "  3. Try 'sudo ls' to test Touch ID authentication"
  elif [[ "$OS" == "arch" ]]; then
    echo "  2. Install Arch packages manually with pacman/yay"
    echo "  3. Adjust configs as needed for your Arch setup"
  fi
  echo ""
  echo "To uninstall symlinks, run: cd ~/dotfiles && stow -D ."
  echo ""
}

main "$@"
