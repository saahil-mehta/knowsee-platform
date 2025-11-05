#!/bin/bash
# Script to run Onyx prod setup locally for testing

set -e

echo "🚀 Starting Onyx in Production Mode (Local Testing)"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from template..."
    if [ -f .env.local-testing ]; then
        cp .env.local-testing .env
        echo "✅ Created .env from .env.local-testing"
    else
        cp env.template .env
        echo "✅ Created .env from env.template"
    fi
    echo "📝 Please edit .env and add your OAuth credentials if needed"
    echo ""
fi

# Check what we're running
echo "📦 Docker Compose Configuration:"
echo "   - Base: docker-compose.prod.yml"
echo "   - Dev overlay: docker-compose.dev.yml (exposes ports)"
echo ""

# Pull latest images (optional, comment out to use local builds)
echo "🔽 Pulling latest images..."
docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml pull

echo ""
echo "🏗️  Building and starting containers..."
docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml up -d --build

echo ""
echo "⏳ Waiting for services to start..."
sleep 10

echo ""
echo "📊 Service Status:"
docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml ps

echo ""
echo "✅ Onyx is starting up! Services available at:"
echo ""
echo "   🌐 Web UI:           http://localhost:3000"
echo "   🔧 API Server:       http://localhost:8080"
echo "   🗄️  Postgres:         localhost:5432"
echo "   🔴 Redis:            localhost:6379"
echo "   🔍 Vespa:            http://localhost:19071"
echo "   📦 MinIO Console:    http://localhost:9005"
echo ""
echo "📝 View logs:"
echo "   docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml logs -f"
echo ""
echo "🛑 Stop everything:"
echo "   docker compose -f docker-compose.prod.yml -f docker-compose.dev.yml down"
echo ""
echo "⚠️  Note: First startup may take 5-10 minutes as services initialize"
echo "    and download ML models. Check logs with the command above."
