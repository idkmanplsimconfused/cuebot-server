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

echo "Setting up the OpenCue database schema..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker exec opencue-postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Waiting for PostgreSQL to be ready... ($i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
        echo "Timed out waiting for PostgreSQL to be ready. Please check your PostgreSQL container."
        exit 1
    fi
done

# Download the schema
if [ ! -f "create_db.sql" ]; then
    echo "Downloading database schema..."
    curl -o create_db.sql https://raw.githubusercontent.com/AcademySoftwareFoundation/OpenCue/master/cuebot/src/main/resources/conf/ddl/postgres/create_db.sql
    if [ $? -ne 0 ]; then
        echo "Failed to download schema. Please check your internet connection."
        exit 1
    fi
fi

# Apply the schema
echo "Applying database schema..."
cat create_db.sql | docker exec -i opencue-postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

if [ $? -eq 0 ]; then
    echo "Database setup complete!"
    echo "OpenCue is now ready to use."
else
    echo "Failed to apply database schema. Please check the logs."
    exit 1
fi 