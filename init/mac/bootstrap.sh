#!/usr/bin/env bash
# bootstrap.sh — fresh-Mac one-liner bootstrap
#
# Run on a fresh Mac:
#   bash -c "$(curl -fsSL https://alan.laird.net/init/mac/bootstrap.sh)"
#
# Installs Homebrew (which pulls Xcode CLT → git), clones the repo,
# then hands off to init/mac/setup.sh.

set -e

REPO_URL="https://github.com/alanlaird/alanlaird.github.io.git"
REPO_DIR="${INIT_DIR:-$HOME/alanlaird.github.io}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { printf "${GREEN}==>${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}[skip]${NC} %s\n" "$1"; }

# ── Homebrew (provides Xcode CLT + git) ─────────────────────────────────────
if ! command -v brew >/dev/null 2>&1; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [ -x /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv)"
else
  warn "Homebrew already installed"
fi

# ── Clone repo ──────────────────────────────────────────────────────────────
if [ -d "$REPO_DIR/.git" ]; then
  warn "$REPO_DIR already exists — pulling latest"
  git -C "$REPO_DIR" pull --ff-only
else
  info "Cloning $REPO_URL → $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
fi

# ── Hand off to setup.sh ────────────────────────────────────────────────────
info "Running init/mac/setup.sh..."
exec "$REPO_DIR/init/mac/setup.sh"
