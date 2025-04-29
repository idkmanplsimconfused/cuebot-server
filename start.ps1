# OpenCue Docker Startup Script for Windows
# PowerShell equivalent of start.sh

# Create a temporary env file if we need to generate docker.env
$TempEnvFile = [System.IO.Path]::GetTempFileName()

# Function to get user input with default value
function Get-UserInput {
    param (
        [string]$Prompt,
        [string]$Default
    )
    
    $input = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrEmpty($input)) {
        return $Default
    }
    return $input
}

# Check if docker.env exists, if not create it
if (-not (Test-Path "docker.env")) {
    Write-Host "docker.env not found, let's configure your environment..."
    
    # Ask for port configurations
    Write-Host "Please specify the ports to use (press Enter to use defaults):"
    
    $CUEBOT_HTTP_PORT = Get-UserInput -Prompt "Cuebot HTTP Port" -Default "8080"
    $CUEBOT_HTTPS_PORT = Get-UserInput -Prompt "Cuebot HTTPS Port" -Default "8443"
    $POSTGRES_PORT = Get-UserInput -Prompt "PostgreSQL Port (external port for host access)" -Default "5432"
    
    # Check if postgres port is already in use
    try {
        $testConnection = New-Object System.Net.Sockets.TcpClient
        $testConnection.Connect("localhost", [int]$POSTGRES_PORT)
        $testConnection.Close()
        
        Write-Host "Warning: Port $POSTGRES_PORT is already in use. Consider using a different port."
        $POSTGRES_PORT = Get-UserInput -Prompt "Choose a different PostgreSQL Port" -Default "5433"
    }
    catch {
        # Port is available
    }
    
    # Create the docker.env file from example
    Copy-Item -Path "docker.env.example" -Destination $TempEnvFile
    
    # Update port settings in the temp env file
    $envContent = Get-Content -Path "docker.env.example"
    $updatedContent = $envContent | ForEach-Object {
        if ($_ -match "^CUEBOT_HTTP_PORT=") {
            "CUEBOT_HTTP_PORT=$CUEBOT_HTTP_PORT"
        }
        elseif ($_ -match "^CUEBOT_HTTPS_PORT=") {
            "CUEBOT_HTTPS_PORT=$CUEBOT_HTTPS_PORT"
        }
        elseif ($_ -match "^POSTGRES_PORT=") {
            "POSTGRES_PORT=$POSTGRES_PORT"
        }
        else {
            $_
        }
    }
    
    # Use the updated content as our docker.env
    $updatedContent | Set-Content -Path "docker.env"
    Remove-Item -Path $TempEnvFile -Force
    
    Write-Host "Created docker.env with your custom settings."
}
else {
    # If docker.env exists but doesn't have port configuration, add defaults
    $envContent = Get-Content -Path "docker.env" -Raw
    if (-not ($envContent -match "CUEBOT_HTTP_PORT")) {
        Add-Content -Path "docker.env" -Value "`n# Port Configuration"
        Add-Content -Path "docker.env" -Value "CUEBOT_HTTP_PORT=8080"
        Add-Content -Path "docker.env" -Value "CUEBOT_HTTPS_PORT=8443"
        Add-Content -Path "docker.env" -Value "POSTGRES_PORT=5432"
        
        Write-Host "Updated docker.env with default port settings."
    }
}

# Ensure CUEBOT_DB_HOST is set to 'postgres'
$envContent = Get-Content -Path "docker.env"
$updatedContent = $envContent | ForEach-Object {
    if ($_ -match "^CUEBOT_DB_HOST=") {
        "CUEBOT_DB_HOST=postgres"
    }
    else {
        $_
    }
}
$updatedContent | Set-Content -Path "docker.env"

# Debug: Print env file content
Write-Host "===== docker.env contents ====="
Get-Content -Path "docker.env"
Write-Host "============================="

# Load environment variables from docker.env
$envContent = Get-Content -Path "docker.env"
$envVars = @{}
foreach ($line in $envContent) {
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith('#')) {
        $key, $value = $line -split '=', 2
        $envVars[$key] = $value
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

# Start OpenCue services
Write-Host "Starting OpenCue services..."

# Force a clean start
docker-compose down
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
Write-Host "Waiting for PostgreSQL to be ready..."
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $result = docker-compose exec postgres pg_isready -U "$($envVars['POSTGRES_USER'])" -d "$($envVars['POSTGRES_DB'])" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "PostgreSQL is ready!"
            $ready = $true
            break
        }
    }
    catch {
        # Command failed, continue waiting
    }
    
    Write-Host "Waiting for PostgreSQL to be ready... ($i/30)"
    Start-Sleep -Seconds 2
    
    if ($i -eq 30) {
        Write-Host "Timed out waiting for PostgreSQL to be ready."
        Write-Host "Starting Cuebot anyway, but it may fail to connect to the database."
    }
}

# Ask the user if they want to setup/initialize the database
$initDb = Read-Host "Do you want to initialize the database with schema and seed data? (y/n) [y]"
if ([string]::IsNullOrEmpty($initDb)) {
    $initDb = "y"
}

if ($initDb -eq "y" -or $initDb -eq "Y") {
    # Call the setup-db.ps1 script if it exists, otherwise use bash script with Docker
    if (Test-Path "setup-db.ps1") {
        & .\setup-db.ps1
    }
    else {
        Write-Host "Using setup-db.sh via Docker..."
        docker run --rm -v ${PWD}:/work -w /work --network="opencue-network" -e POSTGRES_DB=$($envVars['POSTGRES_DB']) -e POSTGRES_USER=$($envVars['POSTGRES_USER']) -e POSTGRES_PASSWORD=$($envVars['POSTGRES_PASSWORD']) ubuntu:20.04 bash setup-db.sh
    }
}

# Start Cuebot
Write-Host "Starting Cuebot..."
docker-compose up -d cuebot

# Wait for services to be ready
Write-Host "Waiting for all services to be ready..."
Start-Sleep -Seconds 10

# Check if services are running
Write-Host "Checking services status:"
docker-compose ps

Write-Host "OpenCue is now available at:"
Write-Host "- Cuebot HTTP: http://localhost:$($envVars['CUEBOT_HTTP_PORT'])"
Write-Host "- Cuebot HTTPS: https://localhost:$($envVars['CUEBOT_HTTPS_PORT'])"
Write-Host "- PostgreSQL: localhost:$($envVars['POSTGRES_PORT']) (external port)"

Write-Host ""
Write-Host "To stop the services, run: .\stop.ps1 or docker-compose down"
Write-Host "To check for connectivity issues, run: .\debug.ps1" 