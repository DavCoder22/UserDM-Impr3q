# Run tests for all services

# Check if Docker is running
$dockerRunning = docker info 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit 1
}

# Load environment variables if .env exists
if (Test-Path .\.env) {
    Get-Content .\.env | ForEach-Object {
        $name, $value = $_.Split('=', 2)
        if ($name -and $value) {
            [System.Environment]::SetEnvironmentVariable($name, $value.Trim('"'), "Process")
        }
    }
}

$services = @(
    "auth-register-service",
    "auth-login-service",
    "auth-profile-service",
    "auth-password-service",
    "auth-logout-service",
    "auth-history-service"
)

$allPassed = $true

foreach ($service in $services) {
    Write-Host "`nRunning tests for $service..." -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $testResult = docker-compose run --rm $service rspec --format documentation --color
    
    if ($LASTEXITCODE -ne 0) {
        $allPassed = $false
        Write-Host "Tests failed for $service" -ForegroundColor Red
    } else {
        Write-Host "Tests passed for $service" -ForegroundColor Green
    }
    
    Write-Host "----------------------------------------"
}

if ($allPassed) {
    Write-Host "`n✅ All tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n❌ Some tests failed." -ForegroundColor Red
    exit 1
}
