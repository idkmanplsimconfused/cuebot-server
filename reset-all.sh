#!/bin/bash

echo "WARNING: This script will delete all OpenCue Docker containers and volumes."
echo "All database data will be permanently lost."
echo ""
read -p "Are you sure you want to continue? (y/n) [n]: " confirm
confirm=${confirm:-n}

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Operation cancelled."
    exit 0
fi

echo "Stopping all running containers..."
docker-compose down

echo "Removing PostgreSQL volume..."
docker volume rm $(docker volume ls -q | grep postgres_data) 2>/dev/null || echo "No PostgreSQL volume found."

echo "Removing OpenCue logs volume..."
docker volume rm $(docker volume ls -q | grep opencue_logs) 2>/dev/null || echo "No OpenCue logs volume found."

echo "Removing any orphaned volumes..."
docker volume prune -f

echo "Removing downloaded SQL files..."
rm -f schema-*.sql seed_data-*.sql create_db.sql 2>/dev/null

echo "Removing docker.env (will be recreated on next start)..."
rm -f docker.env 2>/dev/null

echo "Reset complete. You can now run ./start.sh for a fresh installation."
echo "All data has been removed and you will need to initialize the database again." 