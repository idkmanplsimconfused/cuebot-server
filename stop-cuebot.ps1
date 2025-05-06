# OpenCue Docker Stop Script for Windows
# PowerShell equivalent of stop.sh

# Load environment variables
if (Test-Path "docker.env") {
    $envContent = Get-Content -Path "docker.env"
    foreach ($line in $envContent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith('#')) {
            $key, $value = $line -split '=', 2
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

# Stop OpenCue services
Write-Host "Stopping OpenCue services..."
docker-compose down

Write-Host "Services stopped successfully." 