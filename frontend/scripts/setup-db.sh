#!/bin/bash
set -e

DB_NAME="chatbot"
DB_USER="postgres"
DB_HOST="localhost"
DB_PORT="5432"
COMPOSE_FILE="docker-compose.local.yml"

echo "Checking PostgreSQL status..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

# Check if postgres container exists and is running
if docker ps --format '{{.Names}}' | grep -q "^knowsee-frontend-db$"; then
    echo "PostgreSQL container is already running"
elif docker ps -a --format '{{.Names}}' | grep -q "^knowsee-frontend-db$"; then
    echo "Starting existing PostgreSQL container..."
    docker compose -f "$COMPOSE_FILE" start postgres
    echo "Waiting for PostgreSQL to be ready..."
    sleep 3
else
    echo "Starting PostgreSQL container..."
    docker compose -f "$COMPOSE_FILE" up -d postgres
    echo "Waiting for PostgreSQL to be ready..."
    sleep 5
fi

# Wait for postgres to be healthy
echo "Waiting for PostgreSQL to accept connections..."
MAX_RETRIES=30
RETRY_COUNT=0
until docker exec knowsee-frontend-db pg_isready -U "$DB_USER" > /dev/null 2>&1; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
        echo "Error: PostgreSQL failed to start after $MAX_RETRIES attempts"
        docker compose -f "$COMPOSE_FILE" logs postgres
        exit 1
    fi
    echo "Waiting for PostgreSQL... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 1
done

echo "PostgreSQL is ready"

# Check if database exists
if docker exec knowsee-frontend-db psql -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    echo "Database '$DB_NAME' already exists"
else
    echo "Creating database '$DB_NAME'..."
    docker exec knowsee-frontend-db psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;"
    echo "Database '$DB_NAME' created successfully"
fi

echo "Database setup complete"
