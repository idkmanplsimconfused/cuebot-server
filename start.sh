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

# Platform-independent sed function
sedreplace() {
    # Check if GNU sed or BSD sed
    if sed --version 2>/dev/null | grep -q GNU; then
        # GNU sed
        sed -i "$1" "$2"
    else
        # BSD/macOS sed
        sed -i '' "$1" "$2"
    fi
}

# Check if docker.env exists, if not create it
if [ ! -f "docker.env" ]; then
    echo "docker.env not found, let's configure your environment..."
    
    # Ask for port configurations
    echo "Please specify the ports to use (press Enter to use defaults):"
    
    CUEBOT_HTTP_PORT=$(get_input "Cuebot HTTP Port" "8080")
    CUEBOT_HTTPS_PORT=$(get_input "Cuebot HTTPS Port" "8443")
    POSTGRES_PORT=$(get_input "PostgreSQL Port" "5432")
    
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

# Debug: Print env file content
echo "===== docker.env contents ====="
cat docker.env
echo "============================="

# Start OpenCue services
echo "Starting OpenCue services..."
set -a
source docker.env
set +a
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "Checking services status:"
docker-compose ps

echo "OpenCue is now available at:"
echo "- Cuebot HTTP: http://localhost:$CUEBOT_HTTP_PORT"
echo "- Cuebot HTTPS: https://localhost:$CUEBOT_HTTPS_PORT"

echo ""
echo "To stop the services, run: ./stop.sh or docker-compose down"

# Clean up any temp files if script exits early
trap "rm -f $TEMP_ENV_FILE" EXIT 