#!/usr/bin/env bash

set -euo pipefail

########################################
# Args
########################################

if [ $# -lt 1 ]; then
  echo "Usage: $0 <directory-name> [github-org/repo]"
  exit 1
fi

RAW_NAME="$1"
REPO_SLUG="${2:-}"

NAME=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )
BASE_DIR="./$NAME"

########################################
# Paths
########################################

SSH_DIR="$HOME/.ssh"
DEPLOY_ROOT="$SSH_DIR/deploy-keys"
KEY_DIR="$DEPLOY_ROOT/keys"
CONF_DIR="$DEPLOY_ROOT/config.d"
MAIN_CONFIG="$SSH_DIR/config"

HISTORY_DIR="$HOME/.bootstrap-history"
HISTORY_FILE="$HISTORY_DIR/bootstrap.log"

KEY_PATH="$KEY_DIR/$NAME"
HOST_ALIAS="github-$NAME"
CONF_FILE="$CONF_DIR/$HOST_ALIAS.conf"

########################################
# Logging
########################################

mkdir -p "$HISTORY_DIR"
touch "$HISTORY_FILE"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$HISTORY_FILE"
}

log "Bootstrap start for $NAME"

########################################
# Dependency checks
########################################

for cmd in ssh-keygen ssh git; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo "Missing dependency: $cmd"
    exit 1
  fi
done

########################################
# Directory setup
########################################

mkdir -p "$BASE_DIR"

mkdir -p "$SSH_DIR" "$KEY_DIR" "$CONF_DIR"
chmod 700 "$SSH_DIR" "$DEPLOY_ROOT" "$KEY_DIR" "$CONF_DIR"

touch "$MAIN_CONFIG"
chmod 600 "$MAIN_CONFIG"

########################################
# Ensure Include exists once
########################################

INCLUDE_LINE="Include $CONF_DIR/*.conf"

if ! grep -Fxq "$INCLUDE_LINE" "$MAIN_CONFIG"; then
  echo "" >> "$MAIN_CONFIG"
  echo "$INCLUDE_LINE" >> "$MAIN_CONFIG"
  log "Added SSH Include directive"
fi

########################################
# Key generation (idempotent)
########################################

if [ ! -f "$KEY_PATH" ]; then
  ssh-keygen -t ed25519 -C "deploy-$NAME-$(hostname)" -f "$KEY_PATH" -N ""
  log "Created deploy key $KEY_PATH"
else
  log "Deploy key already exists"
fi

########################################
# Host config (idempotent)
########################################

if [ ! -f "$CONF_FILE" ]; then
  cat > "$CONF_FILE" <<EOF
Host $HOST_ALIAS
  HostName github.com
  User git
  IdentityFile $KEY_PATH
  IdentitiesOnly yes
EOF
  chmod 600 "$CONF_FILE"
  log "Created SSH host config $CONF_FILE"
else
  log "SSH host config already exists"
fi

########################################
# Output public key
########################################

echo
echo "=== Add this deploy key to GitHub ==="
echo "Repo: ${REPO_SLUG:-<not provided>}"
echo
cat "$KEY_PATH.pub"
echo

########################################
# Optional repo flow
########################################

if [ -n "$REPO_SLUG" ]; then

  echo "Open this page to add the key:"
  echo "https://github.com/$REPO_SLUG/settings/keys"
  echo

  read -p "Press ENTER after adding deploy key..."

  log "Testing SSH auth for $HOST_ALIAS"

  set +e
  SSH_OUTPUT=$(ssh -T git@$HOST_ALIAS 2>&1)
  set -e

  echo "$SSH_OUTPUT"

  if echo "$SSH_OUTPUT" | grep -qi "successfully authenticated"; then
    log "SSH authentication success"
  else
    log "SSH test returned non-standard response"
  fi

  if [ ! -d "$BASE_DIR/.git" ]; then
    log "Cloning repository"
    git clone "git@$HOST_ALIAS:$REPO_SLUG.git" "$BASE_DIR"
  else
    log "Repo already exists, skipping clone"
  fi

else
  echo "Next steps:"
  echo "cd $BASE_DIR"
  echo "git clone git@$HOST_ALIAS:OWNER/REPO.git ."
fi

log "Bootstrap complete for $NAME"
