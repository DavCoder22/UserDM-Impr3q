# Clean up development environment for UserDM-Impr3q

# Stop and remove containers, networks, and volumes
docker-compose down -v --remove-orphans

# Remove Docker network
$networkName = "app_network"
$networkExists = docker network ls --filter name=^${networkName}$ --format '{{.Name}}'
if ($networkExists) {
    Write-Host "Removing Docker network: $networkName"
    docker network rm $networkName
}

# Remove Docker images
$images = @(
    "userdm-auth-register-service",
    "userdm-auth-login-service",
    "userdm-auth-profile-service",
    "userdm-auth-password-service",
    "userdm-auth-logout-service",
    "userdm-auth-history-service",
    "postgres:13-alpine",
    "redis:6-alpine",
    "nginx:alpine"
)

foreach ($image in $images) {
    $imageId = docker images -q $image
    if ($imageId) {
        Write-Host "Removing image: $image"
        docker rmi -f $imageId
    }
}

# Clean up dangling images
$danglingImages = docker images -f "dangling=true" -q
if ($danglingImages) {
    Write-Host "Removing dangling images..."
    docker rmi -f $danglingImages
}

# Clean up unused volumes
$unusedVolumes = docker volume ls -f "dangling=true" -q
if ($unusedVolumes) {
    Write-Host "Removing unused volumes..."
    docker volume rm $unusedVolumes
}

# Remove temporary files
$tempFiles = @(
    "traefik/acme.json",
    "traefik/traefik.yml",
    "traefik/logs/*",
    "postgres/initdb/*",
    "redis/data/*"
)

foreach ($file in $tempFiles) {
    if (Test-Path $file) {
        Remove-Item -Path $file -Recurse -Force
        Write-Host "Removed: $file"
    }
}

Write-Host "`nCleanup complete!" -ForegroundColor Green
