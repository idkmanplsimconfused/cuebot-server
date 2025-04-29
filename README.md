# OpenCue Docker Setup

This repository contains Docker Compose configuration for running OpenCue components.

## Components

- **Cuebot**: Core OpenCue service for job management
- **PostgreSQL**: Database for storing OpenCue data

## Getting Started

### Prerequisites

- Git
- Docker

### Setup Instructions

1. Clone this repository
2. Run the start script:

```bash
chmod +x start.sh
./start.sh
```

The script will automatically create a `docker.env` file with default settings if one doesn't exist.

3. Verify the services are running:

```bash
docker-compose ps
```

### Configuration

You can customize the environment variables by:
- Editing the generated `docker.env` file
- Creating your own `docker.env` based on `docker.env.example` before running the start script

Default configuration in `docker.env.example`:

- PostgreSQL
  - Database: `cuebot_local`
  - Username: `cuebot`
  - Password: `changeme`

### Ports

- Cuebot: 8080, 8443
- PostgreSQL: 5432

### Data Persistence

The following data is persisted using Docker volumes:
- `postgres_data`: PostgreSQL database
- `opencue_logs`: OpenCue logs

## Stopping the Services

```bash
chmod +x stop.sh
./stop.sh
```

Alternatively, you can use:
```bash
docker-compose down
```

To completely remove the services and volumes:
```bash
docker-compose down -v
``` 