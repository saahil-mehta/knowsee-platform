#!/bin/bash
# ==============================================================================
# Backend Entrypoint Script
# ==============================================================================
# Runs database migrations before starting the FastAPI server
# ==============================================================================

set -e

echo "=== Knowsee Backend Starting ==="
echo "  Port: ${PORT:-8000}"
echo "  Database: ${POSTGRES_URL}"

# Wait for PostgreSQL to be ready (simple TCP check using Python stdlib)
echo "Waiting for database..."
MAX_RETRIES=30
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if python -c "
import socket
import os

url = os.environ.get('POSTGRES_URL', '')
# Parse host and port from URL like postgresql://user:pass@host:port/db
# Remove protocol prefix
url = url.replace('postgresql://', '').replace('postgres://', '')
# Get host:port part (after @ and before /)
host_port = url.split('@')[-1].split('/')[0]
host = host_port.split(':')[0]
port = int(host_port.split(':')[1]) if ':' in host_port else 5432

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.settimeout(2)
result = sock.connect_ex((host, port))
sock.close()
exit(0 if result == 0 else 1)
" 2>/dev/null; then
        echo "Database is ready!"
        break
    fi

    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "  Database not ready, retrying in 2s... ($RETRY_COUNT/$MAX_RETRIES)"
    sleep 2
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "ERROR: Database not reachable after $MAX_RETRIES attempts"
    exit 1
fi

# Run Alembic migrations
echo "Running database migrations..."
cd /app
alembic -c backend/alembic.ini upgrade head
echo "Migrations complete!"

# Start the FastAPI server
echo "Starting FastAPI server..."
exec uvicorn backend.src.app:app --host 0.0.0.0 --port ${PORT:-8000}
