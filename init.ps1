# Initialize development environment for UserDM-Impr3q

# Check if Docker is running
docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit 1
}

# Check if .env file exists, if not create from example
if (-not (Test-Path .\.env)) {
    if (Test-Path .\.env.example) {
        Write-Host "Creating .env file from example..."
        Copy-Item .\.env.example .\.env
        Write-Host "Please update the .env file with your configuration and run this script again." -ForegroundColor Yellow
        exit 0
    } else {
        Write-Error "No .env.example file found. Please create one first."
        exit 1
    }
}

# Load environment variables
Get-Content .\.env | ForEach-Object {
    $name, $value = $_.Split('=', 2)
    if ($name -and $value) {
        [System.Environment]::SetEnvironmentVariable($name, $value.Trim('"'), "Process")
    }
}

# Create required directories
$directories = @(
    "postgres/initdb",
    "redis/data"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "Created directory: $dir"
    }
}

# Create Docker network if it doesn't exist
$networkName = "app_network"

$networkExists = docker network ls --filter name=^${networkName}$ --format '{{.Name}}'
if (-not $networkExists) {
    Write-Host "Creating Docker network: $networkName"
    docker network create $networkName
} else {
    Write-Host "Docker network '$networkName' already exists" -ForegroundColor Green
}

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Cyan
docker-compose up -d --build

# Wait for services to be ready
Write-Host "Waiting for services to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Run database migrations
Write-Host "Running database migrations..." -ForegroundColor Cyan
try {
    $dbContainer = docker ps --filter "name=db" --format '{{.Names}}'
    if ($dbContainer) {
        $migrationFile = "/docker-entrypoint-initdb.d/001_create_schema.sql"
        $containerMigrationPath = "/docker-entrypoint-initdb.d/$(Split-Path -Leaf $migrationFile)"
        
        # Copy migration file to container
        docker cp $migrationFile "${dbContainer}:${containerMigrationPath}"
        
        # Execute migration
        docker-compose exec -T db psql -U $env.POSTGRES_USER -d $env.POSTGRES_DB -f $containerMigrationPath
        
        Write-Host "Database migrations completed successfully" -ForegroundColor Green
    } else {
        Write-Warning "Database container not found. Migrations not run."
    }
} catch {
    Write-Error "Error running database migrations: $_"
}

# Show service status
Write-Host "`nService Status:" -ForegroundColor Cyan
docker-compose ps

Write-Host "`nAccess the following services:" -ForegroundColor Green
Write-Host "- Traefik Dashboard: https://localhost:8080" -ForegroundColor Cyan
Write-Host "- Health Check: https://localhost/health" -ForegroundColor Cyan
Write-Host "- API Documentation: https://localhost/docs" -ForegroundColor Cyan

Write-Host "`nInitialization complete!" -ForegroundColor Green
