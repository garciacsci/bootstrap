#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "[bootstrap-dev] $1"
}

OS="$(uname -s)"

########################################
# Base packages (Linux)
########################################

if [[ "$OS" == "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
  log "Installing base packages"
  sudo apt-get update -y
  sudo apt-get install -y \
    curl \
    git \
    ca-certificates \
    gnupg \
    jq \
    build-essential
fi

########################################
# Docker
########################################

if [[ "$OS" == "Linux" ]]; then
  if ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    log "Docker installed (run: newgrp docker)"
  else
    log "Docker already installed"
  fi
fi

########################################
# Docker Compose plugin
########################################

if command -v docker >/dev/null 2>&1; then
  if ! docker compose version >/dev/null 2>&1; then
    if command -v apt-get >/dev/null 2>&1; then
      log "Installing Docker Compose plugin"
      sudo apt-get install -y docker-compose-plugin || true
    fi
  else
    log "Docker Compose already available"
  fi
fi

########################################
# Docker buildx (multi-arch builder)
########################################

if command -v docker >/dev/null 2>&1; then
  if ! docker buildx version >/dev/null 2>&1; then
    log "Enabling buildx"
    docker buildx create --use --name multiarch-builder || true
  else
    log "buildx already available"
  fi
fi

########################################
# Install NVM
########################################

if [ ! -d "$HOME/.nvm" ]; then
  log "Installing NVM"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
else
  log "NVM already installed"
fi

########################################
# Load NVM
########################################

export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1090
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

########################################
# Node LTS
########################################

if ! command -v node >/dev/null 2>&1; then
  log "Installing Node LTS"
  nvm install --lts
fi

nvm use --lts
nvm alias default 'lts/*'

########################################
# Corepack + pnpm
########################################

if command -v corepack >/dev/null 2>&1; then
  log "Enabling corepack"
  corepack enable
fi

if ! command -v pnpm >/dev/null 2>&1; then
  log "Installing pnpm"
  corepack prepare pnpm@latest --activate || npm install -g pnpm
else
  log "pnpm already installed"
fi

########################################
# PM2
########################################

if ! command -v pm2 >/dev/null 2>&1; then
  log "Installing PM2"
  pnpm add -g pm2 || npm install -g pm2
else
  log "PM2 already installed"
fi

########################################
# Optional power tools
########################################

if [[ "$OS" == "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
  if ! command -v gh >/dev/null 2>&1; then
    log "Installing GitHub CLI"
    sudo apt-get install -y gh || true
  fi

  if ! command -v lazygit >/dev/null 2>&1; then
    log "Installing lazygit (if available)"
    sudo apt-get install -y lazygit || true
  fi
fi

########################################
# Verification
########################################

echo
echo "Versions:"
echo "Node: $(node -v 2>/dev/null || echo missing)"
echo "pnpm: $(pnpm -v 2>/dev/null || echo missing)"
echo "PM2: $(pm2 -v 2>/dev/null || echo missing)"
echo "Docker: $(docker --version 2>/dev/null || echo missing)"
echo "Buildx: $(docker buildx version 2>/dev/null || echo missing)"

log "bootstrap-dev complete"
