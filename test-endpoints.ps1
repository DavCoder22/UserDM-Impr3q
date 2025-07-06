# test-endpoints.ps1
Write-Host "=== Probando servicios de autenticación ===" -ForegroundColor Cyan

# 1. Probar registro de usuario
Write-Host "`n1. Probando registro de usuario..." -ForegroundColor Yellow
$registerBody = @{
    email = "test@example.com"
    password = "password123"
    nombre = "Usuario de Prueba"
    rol = "usuario"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "http://localhost/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "Registro exitoso:" ($registerResponse | ConvertTo-Json -Depth 5) -ForegroundColor Green
} catch {
    Write-Host "Error en registro:" $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Detalles:" $_.ErrorDetails.Message -ForegroundColor Red
    }
}

# 2. Probar inicio de sesión
Write-Host "`n2. Probando inicio de sesión..." -ForegroundColor Yellow
$loginBody = @{
    email = "test@example.com"
    password = "password123"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://localhost/login" -Method Post -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.token
    Write-Host "Inicio de sesión exitoso. Token recibido." -ForegroundColor Green
    
    # Guardar el token para usarlo en las siguientes peticiones
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
} catch {
    Write-Host "Error en inicio de sesión:" $_.Exception.Message -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Detalles:" $_.ErrorDetails.Message -ForegroundColor Red
    }
    exit
}

# 3. Probar obtención de perfil
if ($token) {
    Write-Host "`n3. Probando obtención de perfil..." -ForegroundColor Yellow
    try {
        $profileResponse = Invoke-RestMethod -Uri "http://localhost/profile" -Headers $headers
        Write-Host "Perfil obtenido correctamente:" ($profileResponse | ConvertTo-Json -Depth 5) -ForegroundColor Green
    } catch {
        Write-Host "Error al obtener perfil:" $_.Exception.Message -ForegroundColor Red
        if ($_.ErrorDetails.Message) {
            Write-Host "Detalles:" $_.ErrorDetails.Message -ForegroundColor Red
        }
    }
}

# 4. Probar cierre de sesión
if ($token) {
    Write-Host "`n4. Probando cierre de sesión..." -ForegroundColor Yellow
    try {
        $logoutResponse = Invoke-RestMethod -Uri "http://localhost/logout" -Headers $headers -Method Post
        Write-Host "Cierre de sesión exitoso." -ForegroundColor Green
    } catch {
        Write-Host "Error en cierre de sesión:" $_.Exception.Message -ForegroundColor Red
    }
}

# 5. Verificar estado de los servicios
Write-Host "`n5. Verificando estado de los servicios..." -ForegroundColor Cyan
$services = @(
    @{Name="Nginx"; Url="http://localhost"},
    @{Name="Registro"; Url="http://localhost/register"},
    @{Name="Login"; Url="http://localhost/login"},
    @{Name="Perfil"; Url="http://localhost/profile"},
    @{Name="Contraseña"; Url="http://localhost/password"},
    @{Name="Cerrar sesión"; Url="http://localhost/logout"},
    @{Name="Historial"; Url="http://localhost/history"},
    @{Name="Health Check"; Url="http://localhost:8080"}
)

foreach ($service in $services) {
    try {
        $status = Invoke-WebRequest -Uri $service.Url -Method Head -UseBasicParsing -ErrorAction Stop
        Write-Host "$($service.Name): ✅ (Status: $($status.StatusCode))" -ForegroundColor Green
    } catch {
        Write-Host "$($service.Name): ❌ Error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Pruebas completadas ===" -ForegroundColor Cyan
