# OpenCue Docker Debug Script for Windows
# PowerShell equivalent of debug.sh

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

Write-Host "============ Environment Variables ============"
Get-Content docker.env
Write-Host "=============================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ Container List ============"
docker ps
Write-Host "==========================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ Network List ============"
docker network ls
Write-Host "============================================"
Write-Host " "
Write-Host " "
Write-Host " "

# volume list
Write-Host "============ Volume List ============"
docker volume ls
Write-Host "==========================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ PostgreSQL Container Logs ============"
docker logs opencue-postgres --tail 30
Write-Host "=================================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ Cuebot Container Logs ============"
docker logs opencue-cuebot --tail 30
Write-Host "=============================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ Port Configuration ============"
Write-Host "External PostgreSQL Port: $($envVars['POSTGRES_PORT']) (mapped to internal port 5432)"
Write-Host "Cuebot HTTP Port: $($envVars['CUEBOT_HTTP_PORT'])"
Write-Host "Cuebot HTTPS Port: $($envVars['CUEBOT_HTTPS_PORT'])"
Write-Host "==========================================="
Write-Host " "
Write-Host " "
Write-Host " "

Write-Host "============ Testing Database Connection ============"
docker exec opencue-postgres psql -U $($envVars['POSTGRES_USER']) -d $($envVars['POSTGRES_DB']) -c "SELECT 1 as connection_test"
Write-Host "===================================================="
Write-Host " "
Write-Host " "
Write-Host " " 