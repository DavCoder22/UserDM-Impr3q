# Monitor logs for all services

param (
    [string]$service = "",
    [switch]$follow = $false,
    [switch]$all = $false,
    [int]$tail = 100
)

# Check if Docker is running
$dockerRunning = docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit 1
}

# Get list of running services
$services = docker-compose ps --services

if (-not $services) {
    Write-Error "No services are running. Start the services first with 'docker-compose up -d'"
    exit 1
}

# If a specific service is provided, show its logs
if ($service) {
    if ($services -contains $service) {
        Write-Host "Showing logs for service: $service" -ForegroundColor Cyan
        if ($follow) {
            docker-compose logs -f --tail=$tail $service
        } else {
            docker-compose logs --tail=$tail $service
        }
    } else {
        Write-Error "Service '$service' not found. Available services: $($services -join ', ')"
        exit 1
    }
    exit 0
}

# Show logs for all services
if ($all) {
    Write-Host "Showing logs for all services (press Ctrl+C to exit)..." -ForegroundColor Cyan
    if ($follow) {
        docker-compose logs -f --tail=$tail
    } else {
        docker-compose logs --tail=$tail
    }
    exit 0
}

# Interactive mode
Write-Host "Select a service to view logs:" -ForegroundColor Cyan
$i = 1
$serviceMap = @{}

foreach ($s in $services) {
    Write-Host "$i. $s"
    $serviceMap[$i] = $s
    $i++
}

Write-Host "$i. All services"
$serviceMap[$i] = "all"

Write-Host ""
$choice = Read-Host "Enter the number of the service (1-$i)"

if (-not ($choice -match '^\d+$') -or [int]$choice -lt 1 -or [int]$choice -gt $i) {
    Write-Error "Invalid selection. Please enter a number between 1 and $i."
    exit 1
}

$selectedService = $serviceMap[[int]$choice]

if ($selectedService -eq "all") {
    Write-Host "Showing logs for all services (press Ctrl+C to exit)..." -ForegroundColor Cyan
    docker-compose logs -f --tail=$tail
} else {
    Write-Host "Showing logs for service: $selectedService (press Ctrl+C to exit)..." -ForegroundColor Cyan
    docker-compose logs -f --tail=$tail $selectedService
}
