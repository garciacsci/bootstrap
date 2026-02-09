#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR="$HOME/.pm2-deploy-services"

for file in "$SERVICE_DIR"/*.env; do
  [ -e "$file" ] || continue

  # shellcheck disable=SC1090
  source "$file"

  echo "Checking updates for $NAME"

  cd "$BASE_DIR"

  git fetch origin "$BRANCH"

  LOCAL=$(git rev-parse HEAD)
  REMOTE=$(git rev-parse "origin/$BRANCH")

  if [ "$LOCAL" != "$REMOTE" ]; then
    echo "Updates found for $NAME"

    git pull origin "$BRANCH"

    pnpm install --frozen-lockfile || pnpm install

    pm2 restart "$NAME"
    pm2 save
  else
    echo "No updates for $NAME"
  fi
done
