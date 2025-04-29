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
chmod +x start.sh setup-db.sh stop.sh debug.sh fix-connection.sh
./start.sh
```

The script will:
- Check if `docker.env` exists
- If not, prompt you to configure ports (or use defaults)
- Create a `docker.env` file with your settings
- Start the PostgreSQL service
- Ask if you want to initialize the database schema and seed data (recommended for first-time setup)
- Start the Cuebot service

3. Verify the services are running:

```bash
docker-compose ps
```

### Database Setup

The first time you run the system, you need to initialize the database schema and seed data. The start script will ask if you want to do this automatically. If you need to do it separately, you can run:

```bash
./setup-db.sh
```

This will:
1. Download the official OpenCue schema (v1.4.11) from GitHub releases
2. Download the official seed data (v1.4.11) from GitHub releases
3. Apply both to your PostgreSQL instance
4. Create a test show and other necessary initial data

### Configuration

You can customize the environment variables by:
- Editing the generated `docker.env` file
- Creating your own `docker.env` based on `docker.env.example` before running the start script

Default configuration in `docker.env.example`:

- PostgreSQL
  - Database: `cuebot_local`
  - Username: `cuebot`
  - Password: `changeme`
- Ports
  - Cuebot HTTP: 8080
  - Cuebot HTTPS: 8443
  - PostgreSQL: 5432

### Ports

Default ports (can be configured during setup):
- Cuebot HTTP: 8080
- Cuebot HTTPS: 8443
- PostgreSQL: 5432

### Data Persistence

The following data is persisted using Docker volumes:
- `postgres_data`: PostgreSQL database
- `opencue_logs`: OpenCue logs

## Stopping the Services

```bash
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

## Troubleshooting

If you encounter any issues with the setup:

```bash
./fix-connection.sh
```

This script will:
1. Stop all services
2. Reset your docker.env to default values
3. Restart services in the correct order
4. Reinitialize the database if requested

### Connection Issues

If Cuebot can't connect to PostgreSQL:

1. Make sure the PostgreSQL container is running:
   ```bash
   docker ps | grep postgres
   ```

2. Check PostgreSQL logs:
   ```bash
   docker logs opencue-postgres
   ```

3. Check Cuebot logs:
   ```bash
   docker logs opencue-cuebot
   ```

4. Run the debug script to diagnose issues:
   ```bash
   ./debug.sh
   ```

### Port Conflicts

If you see "address already in use" errors, you can:

1. Use different ports when prompted during setup
2. Manually edit the `docker.env` file to change ports
3. Stop any running instances of PostgreSQL:
   ```bash
   sudo systemctl stop postgresql
   ``` 