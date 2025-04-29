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

echo "Setting up the OpenCue database schema and seed data..."

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
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

# Download the schema and seed data files from GitHub release
SCHEMA_URL="https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v1.4.11/schema-1.4.11.sql"
SEED_DATA_URL="https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v1.4.11/seed_data-1.4.11.sql"
SCHEMA_FILE="schema-1.4.11.sql"
SEED_DATA_FILE="seed_data-1.4.11.sql"

echo "Downloading schema file from $SCHEMA_URL..."
if [ ! -f "$SCHEMA_FILE" ]; then
    curl -L -o "$SCHEMA_FILE" "$SCHEMA_URL"
    if [ $? -ne 0 ]; then
        echo "Failed to download schema file. Please check your internet connection."
        exit 1
    fi
    echo "Schema file downloaded successfully."
else
    echo "Schema file already exists, using the existing file."
fi

echo "Downloading seed data file from $SEED_DATA_URL..."
if [ ! -f "$SEED_DATA_FILE" ]; then
    curl -L -o "$SEED_DATA_FILE" "$SEED_DATA_URL"
    if [ $? -ne 0 ]; then
        echo "Failed to download seed data file. Please check your internet connection."
        exit 1
    fi
    echo "Seed data file downloaded successfully."
else
    echo "Seed data file already exists, using the existing file."
fi

# Apply the schema
echo "Applying database schema..."
cat "$SCHEMA_FILE" | docker-compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

if [ $? -eq 0 ]; then
    echo "Database schema applied successfully!"
else
    echo "Failed to apply database schema. Please check the logs."
    exit 1
fi

# Apply the seed data
echo "Applying seed data..."
cat "$SEED_DATA_FILE" | docker-compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

if [ $? -eq 0 ]; then
    echo "Seed data applied successfully!"
else
    echo "Failed to apply seed data. Please check the logs."
    exit 1
fi

echo "Database setup completed successfully!"
echo "OpenCue is now ready to use with initial test data." 