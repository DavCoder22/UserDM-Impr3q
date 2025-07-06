# Create the application network if it doesn't exist
$networkName = "app_network"

try {
    $network = docker network ls --filter name=^${networkName}$ --format '{{.Name}}'
    
    if ($network -ne $networkName) {
        Write-Host "Creating Docker network: $networkName"
        docker network create $networkName
        Write-Host "Network $networkName created successfully"
    } else {
        Write-Host "Network $networkName already exists"
    }
} catch {
    Write-Error "Failed to create Docker network: $_"
    exit 1
}

# Create necessary directories
$directories = @(
    "health-check"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
        Write-Host "Created directory: $dir"
    }
}

Write-Host "Setup completed successfully"
