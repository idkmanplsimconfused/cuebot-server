# OpenCue Database Setup Script for Windows
# PowerShell equivalent of setup-db.sh

# Load environment variables
if (Test-Path "docker.env") {
    $envContent = Get-Content -Path "docker.env"
    $envVars = @{}
    foreach ($line in $envContent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith('#')) {
            $key, $value = $line -split '=', 2
            $envVars[$key] = $value
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}
else {
    Write-Host "docker.env not found. Please run .\start.ps1 first."
    exit 1
}

Write-Host "Setting up the OpenCue database schema and seed data..."

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
        Write-Host "Timed out waiting for PostgreSQL to be ready. Please check your PostgreSQL container."
        exit 1
    }
}

# Download the schema and seed data files from GitHub release
$SCHEMA_URL = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v1.4.11/schema-1.4.11.sql"
$SEED_DATA_URL = "https://github.com/AcademySoftwareFoundation/OpenCue/releases/download/v1.4.11/seed_data-1.4.11.sql"
$SCHEMA_FILE = "schema-1.4.11.sql"
$SEED_DATA_FILE = "seed_data-1.4.11.sql"

Write-Host "Downloading schema file from $SCHEMA_URL..."
if (-not (Test-Path $SCHEMA_FILE)) {
    try {
        Invoke-WebRequest -Uri $SCHEMA_URL -OutFile $SCHEMA_FILE
        Write-Host "Schema file downloaded successfully."
    }
    catch {
        Write-Host "Failed to download schema file. Please check your internet connection."
        Write-Host $_.Exception.Message
        exit 1
    }
}
else {
    Write-Host "Schema file already exists, using the existing file."
}

Write-Host "Downloading seed data file from $SEED_DATA_URL..."
if (-not (Test-Path $SEED_DATA_FILE)) {
    try {
        Invoke-WebRequest -Uri $SEED_DATA_URL -OutFile $SEED_DATA_FILE
        Write-Host "Seed data file downloaded successfully."
    }
    catch {
        Write-Host "Failed to download seed data file. Please check your internet connection."
        Write-Host $_.Exception.Message
        exit 1
    }
}
else {
    Write-Host "Seed data file already exists, using the existing file."
}

# Apply the schema
Write-Host "Applying database schema..."
Get-Content $SCHEMA_FILE | docker-compose exec -T postgres psql -U "$($envVars['POSTGRES_USER'])" -d "$($envVars['POSTGRES_DB'])"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Database schema applied successfully!"
}
else {
    Write-Host "Failed to apply database schema. Please check the logs."
    exit 1
}

# Apply the seed data
Write-Host "Applying seed data..."
Get-Content $SEED_DATA_FILE | docker-compose exec -T postgres psql -U "$($envVars['POSTGRES_USER'])" -d "$($envVars['POSTGRES_DB'])"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Seed data applied successfully!"
}
else {
    Write-Host "Failed to apply seed data. Please check the logs."
    exit 1
}

Write-Host "Database setup completed successfully!"
Write-Host "OpenCue is now ready to use with initial test data." 