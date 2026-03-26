#!/usr/bin/env bash
set -euo pipefail

echo "WARNING: This will destroy all containers, volumes, and data."
read -rp "Are you sure? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

echo "Stopping and removing everything..."
docker compose down -v --rmi all

echo "Starting fresh..."
docker compose up -d

echo ""
echo "Done. All services are running fresh."
