#!/bin/bash

# Create a temporary env file if we need to generate docker.env
TEMP_ENV_FILE=$(mktemp)

# Function to get user input with default value
get_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    read -p "$prompt [$default]: " input
    echo "${input:-$default}"
}

# Check if docker.env exists, if not create it
if [ ! -f "docker.env" ]; then
    echo "docker.env not found, let's configure your environment..."
    
    # Ask for port configurations
    echo "Please specify the ports to use (press Enter to use defaults):"
    
    CUEBOT_HTTP_PORT=$(get_input "Cuebot HTTP Port" "8080")
    CUEBOT_HTTPS_PORT=$(get_input "Cuebot HTTPS Port" "8443")
    POSTGRES_PORT=$(get_input "PostgreSQL Port (external port for host access)" "5432")
    
    # Check if postgres port is already in use
    if command -v lsof &> /dev/null && lsof -i ":$POSTGRES_PORT" &> /dev/null; then
        echo "Warning: Port $POSTGRES_PORT is already in use. Consider using a different port."
        POSTGRES_PORT=$(get_input "Choose a different PostgreSQL Port" "5433")
    fi
    
    # Create the docker.env file from example
    cp docker.env.example $TEMP_ENV_FILE
    
    # Update port settings in the temp env file (more portable approach)
    cat docker.env.example | \
        awk -v http_port="$CUEBOT_HTTP_PORT" -v https_port="$CUEBOT_HTTPS_PORT" -v pg_port="$POSTGRES_PORT" '
        {
            if ($0 ~ /^CUEBOT_HTTP_PORT=/) print "CUEBOT_HTTP_PORT=" http_port;
            else if ($0 ~ /^CUEBOT_HTTPS_PORT=/) print "CUEBOT_HTTPS_PORT=" https_port;
            else if ($0 ~ /^POSTGRES_PORT=/) print "POSTGRES_PORT=" pg_port;
            else print $0;
        }' > $TEMP_ENV_FILE
    
    # Use the temp file as our docker.env
    mv $TEMP_ENV_FILE docker.env
    
    echo "Created docker.env with your custom settings."
else
    # If docker.env exists but doesn't have port configuration, add defaults
    if ! grep -q "CUEBOT_HTTP_PORT" docker.env; then
        echo "" >> docker.env
        echo "# Port Configuration" >> docker.env
        echo "CUEBOT_HTTP_PORT=8080" >> docker.env
        echo "CUEBOT_HTTPS_PORT=8443" >> docker.env
        echo "POSTGRES_PORT=5432" >> docker.env
        
        echo "Updated docker.env with default port settings."
    fi
fi

# Ensure CUEBOT_DB_HOST is set to 'postgres'
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

# Debug: Print env file content
echo "===== docker.env contents ====="
cat docker.env
echo "============================="

# Make sure all scripts are executable
chmod +x *.sh 2>/dev/null || true

# Start OpenCue services
echo "Starting OpenCue services..."
set -a
source docker.env
set +a

# Force a clean start
docker-compose down
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if docker-compose exec postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" &> /dev/null; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Waiting for PostgreSQL to be ready... ($i/30)"
    sleep 2
    if [ $i -eq 30 ]; then
        echo "Timed out waiting for PostgreSQL to be ready."
        echo "Starting Cuebot anyway, but it may fail to connect to the database."
    fi
done

# Ask the user if they want to setup/initialize the database
read -p "Do you want to initialize the database with schema and seed data? (y/n) [y]: " init_db
init_db=${init_db:-y}

if [[ $init_db == "y" || $init_db == "Y" ]]; then
    # Call the setup-db.sh script
    ./setup-db.sh
fi

# Start Cuebot
echo "Starting Cuebot..."
docker-compose up -d cuebot

# Wait for services to be ready
echo "Waiting for all services to be ready..."
sleep 10

# Check if services are running
echo "Checking services status:"
docker-compose ps

echo "OpenCue is now available at:"
echo "- Cuebot HTTP: http://localhost:$CUEBOT_HTTP_PORT"
echo "- Cuebot HTTPS: https://localhost:$CUEBOT_HTTPS_PORT"
echo "- PostgreSQL: localhost:$POSTGRES_PORT (external port)"

echo ""
echo "To stop the services, run: ./stop.sh or docker-compose down"
echo "To check for connectivity issues, run: ./debug.sh"

# Clean up any temp files if script exits early
trap "rm -f $TEMP_ENV_FILE" EXIT 