#!/usr/bin/env zsh
# setup.sh — Mac dev environment bootstrap
# Run: ./setup.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo "${GREEN}==>${NC} $1" }
warn() { echo "${YELLOW}[skip]${NC} $1" }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Load brew into this shell for the rest of the script
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
else
  warn "Homebrew already installed"
fi

# ── Brew bundle ─────────────────────────────────────────────────────────────
info "Installing packages from Brewfile..."
brew bundle --file="$SCRIPT_DIR/Brewfile"

# ── Symlink config files ────────────────────────────────────────────────────
link_config() {
  local src="$1"
  local dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    warn "$dst already linked"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    info "Backing up existing $dst → $dst.backup"
    mv "$dst" "$dst.backup"
  fi
  info "Linking $dst → $src"
  mkdir -p "$(dirname "$dst")"
  ln -s "$src" "$dst"
}

link_config "$SCRIPT_DIR/zshrc"               "$HOME/.zshrc"
link_config "$SCRIPT_DIR/aliases.sh"          "$HOME/.aliases.sh"
link_config "$SCRIPT_DIR/ghostty.config"      "$HOME/.config/ghostty/config"
link_config "$SCRIPT_DIR/iterm2_profile.json" "$HOME/Library/Application Support/iTerm2/DynamicProfiles/hermes.json"

# ── Podman machine ──────────────────────────────────────────────────────────
if ! podman machine list 2>/dev/null | grep -q "podman-machine-default"; then
  info "Initializing Podman machine..."
  podman machine init
  podman machine start
else
  warn "Podman machine already initialized"
fi

# ── Python venv ─────────────────────────────────────────────────────────────
PYTHON="$(brew --prefix)/bin/python3"
if [[ ! -d "$HOME/venv" ]]; then
  info "Creating ~/venv with $PYTHON..."
  "$PYTHON" -m venv "$HOME/venv"
else
  warn "~/venv already exists"
fi

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "${GREEN}Done!${NC} Restart your terminal, then run these manual steps:"
echo ""
echo "  p10k configure               # set up prompt theme (writes ~/.p10k.zsh)"
echo "  gcloud init                  # authenticate with GCP"
echo "  aws configure --profile foo  # configure AWS credentials"
echo "  oc login <cluster-url>       # log in to OpenShift"
