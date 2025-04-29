# OpenCue Docker Setup

This repository contains Docker Compose configuration for running OpenCue components.

## Components

- **Cuebot**: Core OpenCue service for job management
- **PostgreSQL**: Database for storing OpenCue data

## Getting Started

### Prerequisites

- Docker
- Docker Compose

### Setup Instructions

1. Clone this repository
2. (Optional) Modify the `docker.env` file to customize settings
3. Start the services:

```bash
docker-compose up -d
```

4. Verify the services are running:

```bash
docker-compose ps
```

### Configuration

The default configuration is available in the `docker.env` file:

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
docker-compose down
```

To completely remove the services and volumes:
```bash
docker-compose down -v
``` 