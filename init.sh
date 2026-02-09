#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="$HOME/bin"
SRC_DIR="$(cd "$(dirname "$0")/bin" && pwd)"

mkdir -p "$BIN_DIR"
chmod 700 "$BIN_DIR"

for file in "$SRC_DIR"/*; do
  name=$(basename "$file")
  ln -sf "$file" "$BIN_DIR/$name"
done

# Ensure PATH contains ~/bin
SHELL_RC="$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC"; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
fi

echo "Installed bootstrap toolkit. Reload shell or run:"
echo "source $SHELL_RC"
