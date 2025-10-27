#!/bin/bash

# ClickHouse Docker Setup Script
# This script sets up the ClickHouse cluster and configures environment variables

set -e

echo "🚀 Setting up ClickHouse cluster with Docker Compose..."

# Check if .env file exists, if not copy from .env.dist
if [ ! -f .env ]; then
    echo "📋 Creating .env file from .env.dist..."
    cp .env.dist .env
    echo "⚠️  Please edit .env file with your configuration before continuing."
    echo "   You can modify the ClickHouse connection settings and Atlas Cloud token."
    echo ""
    read -p "Press Enter to continue after editing .env file..."
fi

# Load environment variables from .env file
echo "🔧 Loading environment variables from .env file..."
export $(grep -v '^#' .env | xargs)

# Start the ClickHouse cluster
echo "📦 Starting ClickHouse containers..."
docker compose up -d

# Wait for ClickHouse to be ready
echo "⏳ Waiting for ClickHouse to be ready..."
sleep 10

# Check if ClickHouse is responding
echo "🔍 Checking ClickHouse connectivity..."
until docker exec clickhouse-demo wget --no-verbose --tries=1 --spider http://localhost:8123/ping; do
    echo "Waiting for ClickHouse to be ready..."
    sleep 2
done

echo "✅ ClickHouse is ready!"

# Create connection URLs
export CLICKHOUSE_URL="clickhouse://$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD@$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/$CLICKHOUSE_DATABASE"
export CLICKHOUSE_DEV_URL="clickhouse://$CLICKHOUSE_USER:$CLICKHOUSE_PASSWORD@$CLICKHOUSE_HOST:$CLICKHOUSE_PORT/$CLICKHOUSE_DEV_DATABASE"

echo "🎉 Setup complete!"
echo ""
echo "📋 Connection details:"
echo "Main database: $CLICKHOUSE_URL"
echo "Dev database: $CLICKHOUSE_DEV_URL"
echo ""
echo "🌐 ClickHouse interface:"
echo "HTTP: http://localhost:8123"
echo "Native: localhost:9000"
echo ""
echo "📝 Environment variables are loaded from .env file"
echo "   To use them in your current shell, run:"
echo "   source .env"
echo ""
echo "🛑 To stop the cluster, run:"
echo "docker compose down"