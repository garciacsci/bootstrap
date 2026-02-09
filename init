#!/usr/bin/env bash

SCRIPT_VERSION="0.1.0"
echo "bootstrap-toolkit install v$SCRIPT_VERSION"

set -euo pipefail

BIN_DIR="$HOME/bin"
SRC_DIR="$(cd "$(dirname "$0")/bin" && pwd)"

echo "Installing bootstrap toolkit..."

mkdir -p "$BIN_DIR"
chmod 700 "$BIN_DIR"

for file in "$SRC_DIR"/*; do
  name="$(basename "$file")"

  # Ensure executable
  chmod +x "$file"

  # Only relink if different
  if [ ! -L "$BIN_DIR/$name" ] || [ "$(readlink "$BIN_DIR/$name" 2>/dev/null)" != "$file" ]; then
    ln -sf "$file" "$BIN_DIR/$name"
    echo "Linked $name"
  fi
done

# Detect shell rc
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

PATH_LINE='export PATH="$HOME/bin:$PATH"'

if ! grep -Fxq "$PATH_LINE" "$SHELL_RC"; then
  echo "" >> "$SHELL_RC"
  echo "$PATH_LINE" >> "$SHELL_RC"
  echo "Added ~/bin to PATH in $SHELL_RC"
fi

echo
echo "Bootstrap toolkit installed."
echo "Reload shell:"
echo "source $SHELL_RC"
