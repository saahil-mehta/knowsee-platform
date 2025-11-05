#!/bin/bash
# Universal startup script for Onyx (Simplified)
# Works for dev, staging, and production

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_msg() {
    color=$1
    shift
    echo -e "${color}$@${NC}"
}

# Detect environment
ENV=${ENV:-development}

print_msg $BLUE "
╔════════════════════════════════════════════════╗
║   Onyx - Simplified Docker Setup              ║
║   Environment: ${ENV}                          ║
╚════════════════════════════════════════════════╝
"

# Select env file
if [ "$ENV" = "production" ]; then
    ENV_FILE=".env.production"
elif [ "$ENV" = "staging" ]; then
    ENV_FILE=".env.staging"
else
    ENV_FILE=".env.development"
fi

# Check if env file exists
if [ ! -f "$ENV_FILE" ]; then
    print_msg $YELLOW "⚠️  $ENV_FILE not found. Creating from template..."
    cp "$ENV_FILE.example" "$ENV_FILE" 2>/dev/null || touch "$ENV_FILE"
    print_msg $YELLOW "📝 Please edit $ENV_FILE with your settings"
    exit 1
fi

print_msg $GREEN "✅ Using environment file: $ENV_FILE"

# Parse arguments
COMMAND=${1:-up}

case $COMMAND in
    up)
        print_msg $BLUE "🚀 Starting Onyx..."
        docker compose -f docker-compose.simple.yml --env-file $ENV_FILE up -d

        print_msg $GREEN "
╔════════════════════════════════════════════════╗
║   Onyx is starting!                            ║
╚════════════════════════════════════════════════╝

⏳ Services are initializing (may take 2-3 minutes on first start)

📊 Service Status:"
        sleep 3
        docker compose -f docker-compose.simple.yml ps

        print_msg $GREEN "
🌐 Access Points:
   Web UI:           http://localhost:3000
   API:              http://localhost:8080
   Postgres:         localhost:5432
   Redis:            localhost:6379
   Vespa:            http://localhost:19071
   MinIO Console:    http://localhost:9001

📝 Useful Commands:
   View logs:        ./start.sh logs
   Stop:             ./start.sh down
   Restart:          ./start.sh restart
   Status:           ./start.sh status
        "
        ;;

    down)
        print_msg $YELLOW "🛑 Stopping Onyx..."
        docker compose -f docker-compose.simple.yml --env-file $ENV_FILE down
        print_msg $GREEN "✅ Onyx stopped"
        ;;

    restart)
        print_msg $YELLOW "🔄 Restarting Onyx..."
        docker compose -f docker-compose.simple.yml --env-file $ENV_FILE restart
        print_msg $GREEN "✅ Onyx restarted"
        ;;

    logs)
        SERVICE=${2:-}
        if [ -z "$SERVICE" ]; then
            docker compose -f docker-compose.simple.yml --env-file $ENV_FILE logs -f
        else
            docker compose -f docker-compose.simple.yml --env-file $ENV_FILE logs -f $SERVICE
        fi
        ;;

    status)
        print_msg $BLUE "📊 Service Status:"
        docker compose -f docker-compose.simple.yml --env-file $ENV_FILE ps
        ;;

    build)
        print_msg $BLUE "🏗️  Building images..."
        docker compose -f docker-compose.simple.yml --env-file $ENV_FILE build
        print_msg $GREEN "✅ Build complete"
        ;;

    clean)
        print_msg $RED "🧹 Cleaning up (this will delete volumes)..."
        read -p "Are you sure? This will delete all data! (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            docker compose -f docker-compose.simple.yml --env-file $ENV_FILE down -v
            print_msg $GREEN "✅ Cleanup complete"
        else
            print_msg $YELLOW "Cleanup cancelled"
        fi
        ;;

    *)
        print_msg $RED "Unknown command: $COMMAND"
        print_msg $YELLOW "
Usage: ./start.sh [command] [options]

Commands:
    up              Start Onyx (default)
    down            Stop Onyx
    restart         Restart Onyx services
    logs [service]  View logs (optionally for specific service)
    status          Show service status
    build           Build Docker images
    clean           Stop and remove all data (destructive!)

Environment:
    Set ENV variable to switch environments:
        ENV=development ./start.sh up  (default)
        ENV=staging ./start.sh up
        ENV=production ./start.sh up

Examples:
    ./start.sh                          # Start in development mode
    ./start.sh logs api                 # View API logs
    ENV=production ./start.sh up        # Start in production mode
        "
        exit 1
        ;;
esac
