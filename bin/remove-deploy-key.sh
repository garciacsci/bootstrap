#!/usr/bin/env bash
set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: remove-deploy-key <name>"
  exit 1
fi

NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' )

KEY_PATH="$HOME/.ssh/deploy-keys/keys/$NAME"
CONF_FILE="$HOME/.ssh/deploy-keys/config.d/github-$NAME.conf"

rm -f "$KEY_PATH" "$KEY_PATH.pub" "$CONF_FILE"

echo "Removed deploy key and SSH config for $NAME"
