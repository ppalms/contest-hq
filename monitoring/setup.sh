#!/bin/bash
set -e

echo "=== Contest HQ Monitoring Stack Setup ==="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    echo "Please create .env from .env.example and configure"
    exit 1
fi

# Load environment variables
source .env

# Verify required variables
if [ -z "$GRAFANA_ADMIN_PASSWORD" ]; then
    echo "Error: GRAFANA_ADMIN_PASSWORD not set in .env"
    exit 1
fi

echo "Starting monitoring stack..."
docker compose up -d

echo ""
echo "=== Monitoring Stack Deployed ==="
echo ""
echo "Services:"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana:    http://localhost:3001"
echo ""
echo "Grafana Credentials:"
echo "  Username: admin"
echo "  Password: ${GRAFANA_ADMIN_PASSWORD}"
echo ""
echo "Checking container status..."
docker compose ps
