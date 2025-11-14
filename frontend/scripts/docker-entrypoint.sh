#!/usr/bin/env sh
set -e

if [ ! -d node_modules ]; then
  echo "Installing frontend dependencies..."
  npm install
fi

exec npm run dev -- --hostname 0.0.0.0 --port 3000
