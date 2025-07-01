<#
.SYNOPSIS
  Pruebas automáticas de los tres microservicios (auth, perfil, historial) en PowerShell.
.DESCRIPTION
  1. Registra usuario y obtiene JWT.
  2. CRUD completo en perfil-service.
  3. Mutación GraphQL en historial-service.
.PARAMETER AuthUrl  URL de auth-service (default http://localhost:4000)
.PARAMETER PerfilUrl URL de perfil-service (default http://localhost:4001)
.PARAMETER HistUrl URL de historial-service (default http://localhost:4002)
.EXAMPLE
  ./test_all.ps1
  ./test_all.ps1 -AuthUrl http://localhost:5000
#>
param(
  [string]$AuthUrl   = "http://localhost:4000",
  [string]$PerfilUrl = "http://localhost:4001",
  [string]$HistUrl   = "http://localhost:4002"
)

function Info($msg) { Write-Host "`n$msg" -ForegroundColor Cyan }

$email = "demo_$((Get-Date -UFormat %s))@example.com"
$pass  = "1234"

# Auth
Info "[Auth] Registrando usuario $email"
try { Invoke-RestMethod -Uri "$AuthUrl/register" -Method Post -ContentType 'application/json' -Body (@{email=$email;password=$pass}|ConvertTo-Json) | Out-Null } catch{}
Info "[Auth] Login y obtención de JWT"
$login = Invoke-RestMethod -Uri "$AuthUrl/login" -Method Post -ContentType 'application/json' -Body (@{email=$email;password=$pass}|ConvertTo-Json)
$token = $login.token
$headers = @{ Authorization = "Bearer $token" }
Write-Host "TOKEN = $token"

# Perfil CRUD
Info "[Perfil] Creando perfil"
$profile = Invoke-RestMethod -Uri "$PerfilUrl/profiles" -Method Post -Headers $headers -ContentType 'application/json' -Body (@{full_name='Demo';avatar_url='https://picsum.photos/200';preferences=@{lang='es'}}|ConvertTo-Json)
$id = $profile.id
Write-Host "Perfil ID = $id"

Info "[Perfil] Consultando perfil"
Invoke-RestMethod "$PerfilUrl/profiles/$id" -Headers $headers | ConvertTo-Json -Depth 4

Info "[Perfil] Patch nombre"
Invoke-WebRequest -Uri "$PerfilUrl/profiles/$id" -Method Patch -Headers $headers -ContentType 'application/json' -Body (@{full_name='Demo2'}|ConvertTo-Json) | Select-Object -ExpandProperty Content

Info "[Perfil] Eliminando perfil"
Invoke-RestMethod -Uri "$PerfilUrl/profiles/$id" -Method Delete -Headers $headers | ConvertTo-Json -Depth 4

# Historial GraphQL
Info "[Historial] Mutación GraphQL createEvent"
$query = 'mutation{createEvent(email:"'+$email+'",event_type:"login",payload:{ip:"127.0.0.1"}){id event_type}}'
$body  = @{ query = $query } | ConvertTo-Json
Invoke-RestMethod -Uri "$HistUrl/graphql" -Method Post -Headers $headers -ContentType 'application/json' -Body $body | ConvertTo-Json -Depth 4

Info "Pruebas completadas"
