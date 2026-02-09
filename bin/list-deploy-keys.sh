#!/usr/bin/env bash
set -euo pipefail

CONF_DIR="$HOME/.ssh/deploy-keys/config.d"

if [ ! -d "$CONF_DIR" ]; then
  echo "No deploy keys configured."
  exit 0
fi

echo "Configured deploy key hosts:"
ls "$CONF_DIR" | sed 's/.conf$//'
