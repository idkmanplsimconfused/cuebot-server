#!/bin/bash

# Load environment variables
if [ -f "docker.env" ]; then
    set -a
    source docker.env
    set +a
fi

# Stop OpenCue services
echo "Stopping OpenCue services..."
docker-compose down

echo "Services stopped successfully." 