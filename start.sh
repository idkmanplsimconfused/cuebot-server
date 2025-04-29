#!/bin/bash

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