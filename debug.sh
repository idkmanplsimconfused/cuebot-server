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
echo "=============================================="
echo " "
echo " "
echo " "

echo "============ Container List ============"
docker ps
echo "==========================================="
echo " "
echo " "
echo " "

echo "============ Network List ============"
docker network ls
echo "============================================"
echo " "
echo " "
echo " "

# volume list
echo "============ Volume List ============"
docker volume ls
echo "==========================================="
echo " "
echo " "
echo " "

echo "============ PostgreSQL Container Logs ============"
docker logs opencue-postgres | tail -30
echo "=================================================="
echo " "
echo " "
echo " "

echo "============ Cuebot Container Logs ============"
docker logs opencue-cuebot | tail -30
echo "=============================================="
echo " "
echo " "
echo " "

echo "============ Port Configuration ============"
echo "External PostgreSQL Port: $POSTGRES_PORT (mapped to internal port 5432)"
echo "Cuebot HTTP Port: $CUEBOT_HTTP_PORT"
echo "Cuebot HTTPS Port: $CUEBOT_HTTPS_PORT"
echo "==========================================="
echo " "
echo " "
echo " "

echo "============ Testing Database Connection ============"
docker exec opencue-postgres psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1 as connection_test"
echo "===================================================="
echo " "
echo " "
echo " "