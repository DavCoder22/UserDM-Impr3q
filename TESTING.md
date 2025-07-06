# Guía de Pruebas y CI/CD

Este documento proporciona una guía completa sobre cómo ejecutar pruebas localmente, entender la cobertura de código y trabajar con el pipeline de CI/CD en el proyecto UserDM-Impr3q.

## Tabla de Contenidos

- [Requisitos Previos](#requisitos-previos)
- [Configuración Inicial](#configuración-inicial)
- [Ejecutar Pruebas](#ejecutar-pruebas)
  - [Ejecutar Todas las Pruebas](#ejecutar-todas-las-pruebas)
  - [Ejecutar un Archivo de Prueba Específico](#ejecutar-un-archivo-de-prueba-específico)
  - [Ejecutar una Prueba Específica](#ejecutar-una-prueba-específica)
  - [Ejecutar Pruebas con Cobertura](#ejecutar-pruebas-con-cobertura)
  - [Ejecutar Pruebas en Paralelo](#ejecutar-pruebas-en-paralelo)
  - [Ejecutar Pruebas en Docker](#ejecutar-pruebas-en-docker)
- [Tareas Rake Disponibles](#tareas-rake-disponibles)
- [Depuración de Pruebas](#depuración-de-pruebas)
- [Cobertura de Código](#cobertura-de-código)
- [Linting y Análisis Estático](#linting-y-análisis-estático)
- [Seguridad](#seguridad)
- [CI/CD Pipeline](#cicd-pipeline)
- [Solución de Problemas](#solución-de-problemas)

## Requisitos Previos

- Ruby 3.2.2
- Node.js 20.x
- PostgreSQL 13+
- Redis 7+
- Bundler 2.4+
- Docker 24+ y Docker Compose 2.20+ (opcional, para pruebas en contenedores)
- Chrome/Chromium (para pruebas del sistema)
- ChromeDriver (versión compatible con tu Chrome)

## Configuración Inicial

1. Clona el repositorio:
   ```bash
   git clone <repositorio>
   cd UserDM-Impr3q
   ```

2. Instala las dependencias:
   ```bash
   bundle install
   ```

3. Configura la base de datos de prueba:
   ```bash
   bundle exec rake setup_test_db
   ```

## Ejecutar Pruebas

### Ejecutar Todas las Pruebas

```bash
bundle exec rspec
```

### Ejecutar un Archivo de Prueba Específico

```bash
bundle exec rspec spec/models/user_spec.rb
```

### Ejecutar una Prueba Específica

```bash
bundle exec rspec spec/models/user_spec.rb:42
```

### Ejecutar Pruebas con Cobertura

```bash
COVERAGE=true bundle exec rspec
```

### Ejecutar Pruebas en Paralelo

Para ejecutar pruebas en paralelo y reducir el tiempo de ejecución:

```bash
# Ejecutar pruebas en 4 procesos
bundle exec parallel_rspec -n 4 spec/

# O usar la tarea rake preconfigurada
bundle exec rake parallel:spec
```

### Ejecutar Pruebas en Docker

```bash
# Construir y ejecutar las pruebas en contenedores
docker-compose -f docker-compose.test.yml up --build --exit-code-from test

# O usar el script de conveniencia
bin/test

# Para depuración interactiva
docker-compose -f docker-compose.test.yml run --service-ports test bash
```

## Tareas Rake Disponibles

```bash
# Ejecutar todas las pruebas
bundle exec rake

# Ejecutar RuboCop
bundle exec rake rubocop

# Verificar cobertura de código
bundle exec rake coverage

# Reiniciar la base de datos de prueba
bundle exec rake reset_test_db

# Ver estado de la base de datos
bundle exec rake db_status

# Ejecutar migraciones
bundle exec rake migrate

# Verificar configuración del entorno
bundle exec rake check_env
```

## Depuración de Pruebas

Para depurar pruebas, puedes usar `binding.pry` en tu código:

```ruby
it 'debe hacer algo' do
  variable = 'valor'
  binding.pry  # La ejecución se detendrá aquí
  expect(variable).to eq('valor')
end
```

## Cobertura de Código

### Ver Cobertura

Para generar un informe de cobertura de código:

```bash
COVERAGE=true bundle exec rspec
open coverage/index.html  # En macOS
# O en Linux:
xdg-open coverage/index.html
```

### Análisis de Cobertura

- **Cobertura general mínima**: 95%
- **Cobertura por archivo mínima**: 85%
- **Archivos críticos**: 100% (controladores de autenticación, modelos de usuario, políticas)
- **Cobertura de ramas**: Habilitada para rutas críticas

### Integración con IDEs

#### VS Code

1. Instala la extensión "Coverage Gutters"
2. Configura la ruta de cobertura en `.vscode/settings.json`:
   ```json
   {
     "coverage-gutters.coverageFileNames": [
       "./coverage/.resultset.json",
       "coverage.xml",
       "lcov.info",
       "coverage/lcov.info"
     ]
   }
   ```
3. Usa `Cmd+Shift+P` > "Coverage Gutters: Display Coverage" para ver la cobertura en el editor

#### RubyMine/IntelliJ

1. Ve a `Run` > `Show Code Coverage Data`
2. Selecciona `coverage/.resultset.json`
3. Usa el panel de cobertura para analizar los resultados

### Generar Informe de Cobertura

```bash
# Generar informe HTML
echo "require 'simplecov'; SimpleCov.coverage_dir('coverage')" > .simplecov
COVERAGE=true bundle exec rspec

# Generar informe LCOV (para Codecov/CI)
COVERAGE=true SIMPLECOV_COMMAND_NAME="RSpec" bundle exec rspec
```

## Linting y Análisis Estático

El proyecto utiliza RuboCop para mantener un estilo de código consistente:

```bash
# Ejecutar RuboCop
bundle exec rubocop

# Corregir automáticamente problemas
bundle exec rubocop -a

# Verificar solo archivos modificados
git diff --name-only | xargs bundle exec rubocop
```

## Seguridad

El proyecto utiliza Brakeman para escanear vulnerabilidades de seguridad:

```bash
# Ejecutar Brakeman
bundle exec brakeman
```

## CI/CD Pipeline

El proyecto utiliza GitHub Actions para la integración y despliegue continuos. El flujo de trabajo principal se encuentra en `.github/workflows/ruby.yml`.

### Estructura del Pipeline

1. **Pruebas (Test Job)**
   - Configuración del entorno (Ruby, Node.js, PostgreSQL, Redis)
   - Instalación de dependencias
   - Ejecución de pruebas unitarias y de integración
   - Cálculo de cobertura de código
   - Subida de resultados a Codecov
   - Ejecución de RuboCop y Brakeman

2. **Seguridad (Security Job)**
   - Escaneo de dependencias con OWASP Dependency-Check
   - Análisis estático de seguridad
   - Generación de reportes de seguridad

3. **Despliegue (Deploy Job)**
   - Construcción de la imagen Docker
   - Despliegue a producción (solo en rama `main`)
   - Notificaciones de despliegue
   - Creación de release en GitHub

### Configuración Requerida

Se requieren los siguientes secretos en el repositorio:

- `JWT_SECRET`: Secreto para firmar tokens JWT
- `DATABASE_URL`: URL de conexión a la base de datos
- `REDIS_URL`: URL de conexión a Redis
- `CODECOV_TOKEN`: Token para subir cobertura a Codecov
- `DOCKERHUB_USERNAME`: Nombre de usuario de Docker Hub
- `DOCKERHUB_TOKEN`: Token de acceso a Docker Hub
- `SLACK_WEBHOOK`: Webhook para notificaciones de Slack (opcional)

### Variables de Entorno

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `RAILS_ENV` | Entorno de Rails | `test` |
| `RACK_ENV` | Entorno de Rack | `test` |
| `JWT_SECRET` | Secreto para JWT | `test-secret-key-1234567890` |
| `COVERAGE` | Habilitar cobertura | `true` |
| `PARALLEL_TEST_PROCESSORS` | Núm. de procesos para pruebas | `4` |

### Monitoreo del Pipeline

- **Estado del Build**: [![CI Status](https://github.com/tu-usuario/UserDM-Impr3q/actions/workflows/ruby.yml/badge.svg)](https://github.com/tu-usuario/UserDM-Impr3q/actions)
- **Cobertura de Código**: [![codecov](https://codecov.io/gh/tu-usuario/UserDM-Impr3q/branch/main/graph/badge.svg)](https://codecov.io/gh/tu-usuario/UserDM-Impr3q)
- **Seguridad**: [![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=UserDM-Impr3q&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=UserDM-Impr3q)

### Despliegue Manual

Para desplegar manualmente una versión específica:

```bash
# Crear un tag
VERSION=1.0.0
git tag -a v$VERSION -m "Release $VERSION"
git push origin v$VERSION

# El workflow de GitHub Actions detectará el tag y desplegará automáticamente
```

### Rollback

Para revertir a una versión anterior:

```bash
# 1. Encontrar el hash del commit anterior
git log --oneline

# 2. Crear un nuevo tag para el rollback
git tag -a v1.0.1-rollback <commit-hash>
git push origin v1.0.1-rollback

# 3. Forzar el despliegue manualmente en GitHub Actions
```

## Solución de Problemas

### Error al conectar a la base de datos

Asegúrate de que PostgreSQL y Redis estén en ejecución:

```bash
# Iniciar PostgreSQL (en macOS con Homebrew)
brew services start postgresql

# Iniciar Redis (en macOS con Homebrew)
brew services start redis
```

### Limpiar la base de datos de prueba

```bash
bundle exec rake reset_test_db
```
### Verificar la configuración del entorno

```bash
bundle exec rake check_env
```

### Problemas con Docker

Si encuentras problemas con Docker, intenta reconstruir las imágenes:

```bash
docker-compose -f docker-compose.test.yml down -v
docker-compose -f docker-compose.test.yml build
```

---

¡Listo! Ahora deberías poder ejecutar y trabajar con las pruebas en el proyecto UserDM-Impr3q sin problemas. Si encuentras algún problema, no dudes en abrir un issue en el repositorio.
