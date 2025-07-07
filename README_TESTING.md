# Sistema de Pruebas y Microservicios - UserDM-Impr3q

Este documento describe cómo configurar, ejecutar y probar el sistema completo de microservicios de autenticación y gestión de usuarios.

## 🏗️ Arquitectura del Sistema

El sistema está compuesto por los siguientes microservicios:

### Servicios de Autenticación
- **auth-register-service** (Puerto 3001) - Registro de usuarios
- **auth-login-service** (Puerto 3002) - Inicio de sesión
- **auth-profile-service** (Puerto 3003) - Gestión de perfiles básicos
- **auth-password-service** (Puerto 3004) - Cambio de contraseñas
- **auth-logout-service** (Puerto 3005) - Cierre de sesión
- **auth-history-service** (Puerto 3006) - Historial de actividades

### Servicios Principales
- **perfil-service** (Puerto 3007) - Gestión completa de perfiles
- **historial-service** (Puerto 3008) - Gestión completa de historial

### Infraestructura
- **PostgreSQL** (Puerto 5436) - Base de datos
- **Redis** (Puerto 6380) - Cache y sesiones
- **Swagger UI** (Puerto 8080) - Documentación de API

## 🚀 Configuración Inicial

### Prerrequisitos
- Docker Desktop instalado y ejecutándose
- PowerShell (Windows) o Bash (Linux/Mac)
- Al menos 4GB de RAM disponible

### 1. Verificar y Corregir Dockerfiles

```powershell
# Verificar que todos los microservicios tengan Dockerfiles correctos
.\fix_microservice_dockerfiles.ps1
```

Este script:
- Verifica la existencia de Dockerfiles en cada microservicio
- Crea Dockerfiles estándar si no existen
- Verifica Gemfiles y dependencias
- Crea estructura de directorios si es necesario

### 2. Ejecutar Pruebas Completas

```powershell
# Ejecutar todas las pruebas con Docker Compose
.\run_complete_tests.ps1
```

Opciones disponibles:
```powershell
# Solo pruebas unitarias
.\run_complete_tests.ps1 -TestType unit

# Solo pruebas de integración
.\run_complete_tests.ps1 -TestType integration

# Solo pruebas de API
.\run_complete_tests.ps1 -TestType api

# Saltar verificación de salud de servicios
.\run_complete_tests.ps1 -SkipHealthCheck

# Saltar información de Swagger
.\run_complete_tests.ps1 -SkipSwagger
```

### 3. Probar Endpoints de Microservicios

```powershell
# Probar todos los endpoints
.\test_microservice_endpoints.ps1

# Solo health checks
.\test_microservice_endpoints.ps1 -OnlyHealthCheck

# Saltar flujo de autenticación
.\test_microservice_endpoints.ps1 -SkipAuthFlow
```

## 📋 Flujo de Pruebas

### 1. Verificación de Infraestructura
- Verificar que Docker esté ejecutándose
- Limpiar contenedores anteriores
- Construir y levantar servicios

### 2. Health Checks
- Verificar que todos los servicios respondan
- Comprobar conectividad de base de datos
- Verificar conectividad de Redis

### 3. Pruebas de Autenticación
- Registro de usuario de prueba
- Inicio de sesión
- Obtención de token JWT
- Prueba de endpoints protegidos
- Cierre de sesión

### 4. Pruebas de RSpec
- Pruebas unitarias de modelos
- Pruebas de integración
- Pruebas de API
- Pruebas de autenticación

## 🔧 Configuración de Docker Compose

### Archivo Principal: `docker-compose.yml`
Configuración para producción con todos los servicios.

### Archivo de Pruebas: `docker-compose.test.yml`
Configuración específica para pruebas con:
- Base de datos de prueba separada
- Redis de prueba
- Todos los microservicios en modo test
- Swagger UI para documentación

## 📚 Documentación de API

### Swagger UI
Una vez que los servicios estén ejecutándose, la documentación estará disponible en:
```
http://localhost:8080
```

### Endpoints Principales

#### Autenticación
- `POST /register` - Registro de usuario
- `POST /login` - Inicio de sesión
- `DELETE /logout` - Cierre de sesión
- `GET /me` - Información del usuario actual

#### Perfiles
- `GET /api/v1/profile` - Obtener perfil actual
- `PUT /api/v1/profile` - Crear/actualizar perfil
- `PUT /api/v1/profile/avatar` - Actualizar avatar

#### Historial
- `GET /api/v1/history` - Obtener historial del usuario
- `GET /api/v1/history/{id}` - Obtener registro específico

## 🧪 Tipos de Pruebas

### Pruebas Unitarias
```powershell
.\run_complete_tests.ps1 -TestType unit
```
Prueban modelos y lógica de negocio individual.

### Pruebas de Integración
```powershell
.\run_complete_tests.ps1 -TestType integration
```
Prueban la interacción entre componentes.

### Pruebas de API
```powershell
.\run_complete_tests.ps1 -TestType api
```
Prueban endpoints HTTP y respuestas.

## 🔍 Troubleshooting

### Problemas Comunes

#### 1. Docker no está ejecutándose
```powershell
# Verificar estado de Docker
docker version
```

#### 2. Puertos ocupados
```powershell
# Verificar puertos en uso
netstat -an | findstr ":300"
```

#### 3. Servicios no responden
```powershell
# Ver logs de servicios
docker-compose -f docker-compose.test.yml logs

# Ver logs de un servicio específico
docker-compose -f docker-compose.test.yml logs auth-register-service
```

#### 4. Problemas de base de datos
```powershell
# Verificar conexión a PostgreSQL
docker-compose -f docker-compose.test.yml exec test_db psql -U postgres -d auth_db_test -c "SELECT 1;"
```

#### 5. Problemas de Redis
```powershell
# Verificar conexión a Redis
docker-compose -f docker-compose.test.yml exec test_redis redis-cli -a test_password ping
```

### Limpieza de Contenedores

```powershell
# Detener y eliminar todos los contenedores
docker-compose -f docker-compose.test.yml down -v

# Limpiar imágenes no utilizadas
docker system prune -f

# Limpiar volúmenes
docker volume prune -f
```

## 📊 Monitoreo

### Verificar Estado de Servicios
```powershell
# Ver servicios ejecutándose
docker-compose -f docker-compose.test.yml ps

# Ver uso de recursos
docker stats
```

### Logs en Tiempo Real
```powershell
# Ver logs de todos los servicios
docker-compose -f docker-compose.test.yml logs -f

# Ver logs de un servicio específico
docker-compose -f docker-compose.test.yml logs -f test_auth_register
```

## 🚀 Despliegue

### Para Desarrollo
```powershell
# Levantar servicios de desarrollo
docker-compose up -d

# Verificar servicios
.\test_microservice_endpoints.ps1 -OnlyHealthCheck
```

### Para Producción
```powershell
# Levantar servicios de producción
docker-compose -f docker-compose.yml up -d

# Verificar servicios
docker-compose -f docker-compose.yml ps
```

## 📝 Notas Importantes

1. **Variables de Entorno**: Asegúrate de tener un archivo `.env` con las variables necesarias
2. **Base de Datos**: Las migraciones se ejecutan automáticamente al iniciar los contenedores
3. **Tokens JWT**: Los tokens tienen un tiempo de expiración configurable
4. **CORS**: Los servicios están configurados para permitir peticiones desde cualquier origen en desarrollo
5. **Logs**: Los logs se guardan en `/app/logs` dentro de cada contenedor

## 🤝 Contribución

Para contribuir al proyecto:

1. Ejecuta las pruebas antes de hacer cambios
2. Asegúrate de que todas las pruebas pasen
3. Actualiza la documentación si es necesario
4. Verifica que los endpoints funcionen correctamente

## 📞 Soporte

Si encuentras problemas:

1. Revisa los logs de Docker
2. Verifica la configuración de red
3. Asegúrate de que todos los servicios estén ejecutándose
4. Consulta la documentación de Swagger

---

**Desarrollado por el Equipo de UserDM-Impr3q** 🚀 