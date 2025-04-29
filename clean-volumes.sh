#!/bin/bash

# Function to display usage instructions
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  --all         Delete all OpenCue volumes and containers (default)"
    echo "  --db-only     Delete only the PostgreSQL database volume"
    echo "  --logs-only   Delete only the OpenCue logs volume"
    echo "  --files-only  Delete only the downloaded SQL files"
    echo "  --help        Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0            Interactive mode, asks for confirmation"
    echo "  $0 --all      Delete all volumes without confirmation"
    echo "  $0 --db-only  Delete only the database volume"
}

# Default values
DELETE_DB=false
DELETE_LOGS=false
DELETE_FILES=false
DELETE_CONFIG=false
INTERACTIVE=true

# Parse arguments
if [ $# -eq 0 ]; then
    # Default is to delete everything, but ask for confirmation
    DELETE_DB=true
    DELETE_LOGS=true
    DELETE_FILES=true
    DELETE_CONFIG=true
else
    for arg in "$@"; do
        case $arg in
            --all)
                DELETE_DB=true
                DELETE_LOGS=true
                DELETE_FILES=true
                DELETE_CONFIG=true
                INTERACTIVE=false
                ;;
            --db-only)
                DELETE_DB=true
                INTERACTIVE=false
                ;;
            --logs-only)
                DELETE_LOGS=true
                INTERACTIVE=false
                ;;
            --files-only)
                DELETE_FILES=true
                INTERACTIVE=false
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $arg"
                usage
                exit 1
                ;;
        esac
    done
fi

# Show warning and ask for confirmation if in interactive mode
if [ "$INTERACTIVE" = true ]; then
    echo "WARNING: This script will delete OpenCue Docker volumes and data."
    echo "The following will be deleted:"
    [ "$DELETE_DB" = true ] && echo "- PostgreSQL database volume (all database data)"
    [ "$DELETE_LOGS" = true ] && echo "- OpenCue logs volume"
    [ "$DELETE_FILES" = true ] && echo "- Downloaded SQL files"
    [ "$DELETE_CONFIG" = true ] && echo "- docker.env configuration file"
    echo ""
    read -p "Are you sure you want to continue? (y/n) [n]: " confirm
    confirm=${confirm:-n}

    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Stop running containers first
echo "Stopping all running containers..."
docker-compose down

# Handle each deletion separately
if [ "$DELETE_DB" = true ]; then
    echo "Removing PostgreSQL volume..."
    VOL_COUNT=$(docker volume ls -q | grep postgres_data | wc -l)
    if [ "$VOL_COUNT" -gt 0 ]; then
        docker volume rm $(docker volume ls -q | grep postgres_data)
        echo "PostgreSQL volume removed."
    else
        echo "No PostgreSQL volume found."
    fi
fi

if [ "$DELETE_LOGS" = true ]; then
    echo "Removing OpenCue logs volume..."
    VOL_COUNT=$(docker volume ls -q | grep opencue_logs | wc -l)
    if [ "$VOL_COUNT" -gt 0 ]; then
        docker volume rm $(docker volume ls -q | grep opencue_logs)
        echo "OpenCue logs volume removed."
    else
        echo "No OpenCue logs volume found."
    fi
fi

if [ "$DELETE_FILES" = true ]; then
    echo "Removing downloaded SQL files..."
    COUNT=$(ls schema-*.sql seed_data-*.sql create_db.sql 2>/dev/null | wc -l)
    if [ "$COUNT" -gt 0 ]; then
        rm -f schema-*.sql seed_data-*.sql create_db.sql
        echo "SQL files removed."
    else
        echo "No SQL files found."
    fi
fi

if [ "$DELETE_CONFIG" = true ]; then
    echo "Removing docker.env (will be recreated on next start)..."
    if [ -f "docker.env" ]; then
        rm -f docker.env
        echo "docker.env removed."
    else
        echo "No docker.env file found."
    fi
fi

echo "Cleanup completed."
echo "You can now run ./start.sh for a fresh installation."
if [ "$DELETE_DB" = true ]; then
    echo "Remember to initialize the database again during startup." 