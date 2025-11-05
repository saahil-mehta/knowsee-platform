#!/bin/sh
set -eu

# Install dependencies when the node_modules volume is empty.
if [ ! -f node_modules/.bin/next ]; then
  echo "Installing frontend dependencies..."
  npm install --no-audit --prefer-offline
fi

exec npm run dev
