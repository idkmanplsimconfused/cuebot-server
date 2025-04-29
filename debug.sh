#!/bin/bash

# Load environment variables
if [ -f "docker.env" ]; then
    set -a
    source docker.env
    set +a
else
    echo "docker.env not found. Please run ./start.sh first."
    exit 1
fi

echo "============ Environment Variables ============"
cat docker.env
echo "==============================================\n\n\n"

echo "============ Container List ============"
docker ps
echo "===========================================\n\n\n"

echo "============ Network List ============"
docker network ls
echo "===========================================\n\n\n"

echo "============ PostgreSQL Container Logs ============"
docker logs opencue-postgres | tail -30
echo "==================================================\n\n\n"

echo "============ Cuebot Container Logs ============"
docker logs opencue-cuebot | tail -30
echo "===============================================\n\n\n"

echo "============ Port Configuration ============"
echo "External PostgreSQL Port: $POSTGRES_PORT (mapped to internal port 5432)"
echo "Cuebot HTTP Port: $CUEBOT_HTTP_PORT"
echo "Cuebot HTTPS Port: $CUEBOT_HTTPS_PORT"
echo "===========================================\n\n\n"

echo "============ Testing Database Connection ============"
docker exec opencue-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1 as connection_test"
echo "===================================================\n\n\n"

echo "============ Testing Network Connection from Cuebot to PostgreSQL ============"
docker exec opencue-cuebot ping -c 4 postgres
echo "========================================================================"