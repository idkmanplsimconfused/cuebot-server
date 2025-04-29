#!/bin/bash

# Check if docker.env exists, if not create it from example
if [ ! -f "docker.env" ]; then
    echo "docker.env not found, creating from docker.env.example..."
    cp docker.env.example docker.env
    echo "Created docker.env with default values."
    echo "You may want to edit docker.env to customize your settings."
    echo ""
fi

# Start OpenCue services
echo "Starting OpenCue services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Check if services are running
echo "Checking services status:"
docker-compose ps

echo "OpenCue is now available at:"
echo "- Cuebot: http://localhost:8080"

echo ""
echo "To stop the services, run: docker-compose down" 