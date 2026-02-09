#!/usr/bin/env bash
set -euo pipefail

HISTORY_DIR="$HOME/.bootstrap-history"
HISTORY_FILE="$HISTORY_DIR/bootstrap.log"

log() {
  mkdir -p "$HISTORY_DIR"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HISTORY_FILE"
}

SCRIPT_VERSION="0.2.0"
log "bootstrap-machine v$SCRIPT_VERSION start"

########################################
# Ensure ~/bin on PATH
########################################

BIN_DIR="$HOME/bin"
mkdir -p "$BIN_DIR"
chmod 700 "$BIN_DIR"

SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
  log "Added ~/bin to PATH in $SHELL_RC"
fi

########################################
# SSH structure
########################################

SSH_DIR="$HOME/.ssh"
DEPLOY_ROOT="$SSH_DIR/deploy-keys"
KEY_DIR="$DEPLOY_ROOT/keys"
CONF_DIR="$DEPLOY_ROOT/config.d"
META_DIR="$DEPLOY_ROOT/meta"

mkdir -p "$SSH_DIR" "$KEY_DIR" "$CONF_DIR" "$META_DIR"
chmod 700 "$SSH_DIR" "$DEPLOY_ROOT" "$KEY_DIR" "$CONF_DIR" "$META_DIR"

MAIN_CONFIG="$SSH_DIR/config"
touch "$MAIN_CONFIG"
chmod 600 "$MAIN_CONFIG"

INCLUDE_LINE="Include $CONF_DIR/*.conf"
if ! grep -Fxq "$INCLUDE_LINE" "$MAIN_CONFIG"; then
  echo "" >> "$MAIN_CONFIG"
  echo "$INCLUDE_LINE" >> "$MAIN_CONFIG"
  log "Added SSH Include directive"
fi

########################################
# Install base packages (Debian/Ubuntu)
########################################

if command -v apt-get >/dev/null 2>&1; then
  log "Installing base packages via apt"
  sudo apt-get update -y
  sudo apt-get install -y git curl ca-certificates gnupg
fi

########################################
# Docker group setup (if docker present)
########################################

if command -v docker >/dev/null 2>&1; then
  if groups "$USER" | grep -q '\bdocker\b'; then
    log "User already in docker group"
  else
    log "Adding $USER to docker group"
    sudo usermod -aG docker "$USER"
    log "Run: newgrp docker  (or log out/in)"
  fi
fi

########################################
# Git defaults
########################################

if ! git config --global user.name >/dev/null; then
  git config --global init.defaultBranch main
  git config --global pull.rebase true
  log "Set basic git defaults"
fi

log "bootstrap-machine complete"
echo
if command -v docker >/dev/null 2>&1; then
  echo "Run: newgrp docker"
  echo
fi
echo "Reload shell or run:"
echo "source $SHELL_RC"
