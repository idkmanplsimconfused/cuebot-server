#!/bin/bash

echo "This script will fix connection issues between Cuebot and PostgreSQL"

# Stop and remove containers
echo "Stopping existing containers..."
docker-compose down

# Create temp file
TEMP_FILE=$(mktemp)

# Backup docker.env
if [ -f "docker.env" ]; then
    cp docker.env docker.env.backup
    echo "Backed up docker.env to docker.env.backup"
fi

# Create docker.env from example
echo "Creating fresh docker.env from example..."
cp docker.env.example docker.env

# Ensure CUEBOT_DB_HOST is set to 'postgres' (this is critical)
if grep -q "CUEBOT_DB_HOST=" docker.env; then
    # Platform-independent sed
    if sed --version 2>/dev/null | grep -q GNU; then
        # GNU sed
        sed -i "s/CUEBOT_DB_HOST=.*/CUEBOT_DB_HOST=postgres/" docker.env
    else
        # BSD/macOS sed
        sed -i '' "s/CUEBOT_DB_HOST=.*/CUEBOT_DB_HOST=postgres/" docker.env
    fi
fi

# Make all scripts executable
chmod +x *.sh 2>/dev/null || true

# Load the environment
set -a
source docker.env
set +a

# Restart containers properly
echo "Starting PostgreSQL container..."
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec postgres pg_isready -U cuebot -d cuebot_local &> /dev/null; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Waiting for PostgreSQL to be ready... ($i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
        echo "Timed out waiting for PostgreSQL to be ready."
        exit 1
    fi
done

# Initialize database if needed
read -p "Do you want to initialize the database schema? (y/n) [y]: " init_db
init_db=${init_db:-y}

if [[ $init_db == "y" || $init_db == "Y" ]]; then
    # Download schema if needed
    if [ ! -f "create_db.sql" ]; then
        echo "Downloading database schema..."
        curl -o create_db.sql https://raw.githubusercontent.com/AcademySoftwareFoundation/OpenCue/master/cuebot/src/main/resources/conf/ddl/postgres/create_db.sql
    fi
    
    # Apply schema
    echo "Applying database schema..."
    cat create_db.sql | docker-compose exec -T postgres psql -U cuebot -d cuebot_local
    
    if [ $? -eq 0 ]; then
        echo "Database initialized successfully!"
    else
        echo "Database initialization failed!"
        exit 1
    fi
fi

# Start Cuebot
echo "Starting Cuebot..."
docker-compose up -d cuebot

echo "Waiting for services to start..."
sleep 5

# Check if Cuebot is running
if docker ps | grep -q opencue-cuebot; then
    echo "Cuebot is running!"
else
    echo "Cuebot failed to start. Check logs with:"
    echo "docker logs opencue-cuebot"
    exit 1
fi

echo "Fix completed! You can check the status with:"
echo "./debug.sh"

# Display connection information
echo ""
echo "OpenCue is now available at:"
echo "- Cuebot HTTP: http://localhost:$CUEBOT_HTTP_PORT"
echo "- Cuebot HTTPS: https://localhost:$CUEBOT_HTTPS_PORT"
echo "- PostgreSQL: localhost:$POSTGRES_PORT (external port)" 