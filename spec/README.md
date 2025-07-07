# Guía de Pruebas - Sistema de Autenticación

## 📋 Descripción

Este directorio contiene todas las pruebas del sistema de autenticación basado en Sinatra y PostgreSQL.

## 🚀 Configuración Inicial

### Prerrequisitos

1. **Ruby** (versión 2.7 o superior)
   ```bash
   # Verificar versión
   ruby --version
   ```

2. **Bundler**
   ```bash
   # Instalar si no está disponible
   gem install bundler
   ```

3. **PostgreSQL**
   - Instalar PostgreSQL en tu sistema
   - Crear una base de datos de prueba: `auth_db_test`
   - Configurar credenciales en variables de entorno

### Instalación

1. **Instalar dependencias**
   ```bash
   bundle install
   ```

2. **Configurar variables de entorno**
   ```bash
   # Crear archivo .env.test (opcional)
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=auth_db_test
   DB_USER=postgres
   DB_PASSWORD=postgres
   JWT_SECRET=test-secret-key-1234567890
   ```

3. **Ejecutar script de configuración**
   ```bash
   # En Windows
   .\run_tests.ps1
   
   # En Linux/Mac
   ./run_tests.sh
   ```

## 🧪 Ejecutar Pruebas

### Comandos Básicos

```bash
# Ejecutar todas las pruebas
bundle exec rspec

# Ejecutar con formato detallado
bundle exec rspec --format documentation

# Ejecutar pruebas específicas
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/auth_controller_spec.rb

# Ejecutar pruebas con filtro
bundle exec rspec --tag authentication
bundle exec rspec --tag integration
```

### Opciones Avanzadas

```bash
# Ejecutar con cobertura de código
bundle exec rspec --format progress --format html --out coverage/report.html

# Ejecutar pruebas en paralelo (si tienes parallel_tests)
bundle exec parallel_rspec spec/

# Ejecutar pruebas con profiling
bundle exec rspec --profile

# Ejecutar pruebas con seed específico
bundle exec rspec --seed 12345
```

## 📁 Estructura de Pruebas

```
spec/
├── models/                 # Pruebas de modelos
│   ├── user_spec.rb       # Pruebas del modelo User
│   ├── session_spec.rb    # Pruebas del modelo Session
│   └── profile_spec.rb    # Pruebas del modelo Profile
├── controllers/           # Pruebas de controladores
│   └── auth_controller_spec.rb
├── integration/          # Pruebas de integración
├── factories/           # Factories para datos de prueba
│   ├── user_factory.rb
│   └── session_factory.rb
├── support/             # Archivos de soporte
│   ├── database_setup.rb
│   ├── factory_bot.rb
│   └── test_environment.rb
└── spec_helper.rb       # Configuración principal
```

## 🔧 Configuración de Base de Datos

### Configuración Automática

El sistema automáticamente:
- Crea las tablas necesarias en la base de datos de prueba
- Limpia los datos entre pruebas
- Configura las conexiones correctas

### Configuración Manual

Si necesitas configurar manualmente:

```sql
-- Crear base de datos de prueba
CREATE DATABASE auth_db_test;

-- Ejecutar migraciones
\c auth_db_test
\i db/migrations/001_create_schema.sql
\i db/migrations/002_add_auth_tables.sql
```

## 🐛 Solución de Problemas

### Error: "Ruby no encontrado"
```bash
# Instalar Ruby desde https://www.ruby-lang.org/en/downloads/
# O usar un gestor de versiones como rbenv o rvm
```

### Error: "Bundler no encontrado"
```bash
gem install bundler
```

### Error: "No se puede conectar a PostgreSQL"
```bash
# Verificar que PostgreSQL esté ejecutándose
# En Windows:
net start postgresql

# En Linux:
sudo systemctl start postgresql

# En Mac:
brew services start postgresql
```

### Error: "Database connection failed"
```bash
# Verificar credenciales en variables de entorno
echo $DB_HOST $DB_PORT $DB_NAME $DB_USER

# Probar conexión manual
psql -h localhost -p 5432 -U postgres -d auth_db_test
```

### Error: "Factory not found"
```bash
# Verificar que las factories estén cargadas
bundle exec rspec --require spec/factories/user_factory.rb
```

### Error: "JWT_SECRET not set"
```bash
# Configurar variable de entorno
export JWT_SECRET=test-secret-key-1234567890
# O agregar al archivo .env.test
```

## 📊 Cobertura de Código

### Ver Cobertura

```bash
# Ejecutar pruebas con cobertura
bundle exec rspec

# Abrir reporte HTML
open coverage/index.html  # Mac
start coverage/index.html  # Windows
xdg-open coverage/index.html  # Linux
```

### Umbrales de Cobertura

- **General**: 80% mínimo
- **Archivos críticos**: 100% mínimo
- **Archivos por defecto**: 70% mínimo

### Archivos Críticos

- `models/user.rb`
- `models/session.rb`
- `controllers/auth_controller.rb`
- `lib/jwt_auth.rb`
- `lib/auth_helper.rb`

## 🏷️ Tags de Pruebas

```ruby
# Usar tags para organizar pruebas
RSpec.describe User, :authentication do
  it 'authenticates user', :integration do
    # prueba aquí
  end
end

# Ejecutar por tags
bundle exec rspec --tag authentication
bundle exec rspec --tag integration
bundle exec rspec --tag slow
```

## 🔄 CI/CD

### GitHub Actions

El proyecto incluye configuración para GitHub Actions que:
- Ejecuta pruebas automáticamente en cada push
- Genera reportes de cobertura
- Falla si la cobertura es insuficiente

### Variables de Entorno en CI

```yaml
env:
  DB_HOST: localhost
  DB_PORT: 5432
  DB_NAME: auth_db_test
  DB_USER: postgres
  DB_PASSWORD: postgres
  JWT_SECRET: ci-secret-key
```

## 📝 Mejores Prácticas

1. **Nombres descriptivos**: Usar nombres claros para las pruebas
2. **Una aserción por prueba**: Cada prueba debe verificar una cosa
3. **Datos de prueba**: Usar factories para crear datos consistentes
4. **Limpieza**: Las pruebas deben limpiar después de sí mismas
5. **Independencia**: Las pruebas no deben depender entre sí

## 🤝 Contribuir

1. Escribir pruebas para nuevo código
2. Mantener cobertura de código alta
3. Seguir las convenciones de nomenclatura
4. Documentar pruebas complejas

## 📞 Soporte

Si encuentras problemas:
1. Revisar esta documentación
2. Verificar la configuración de base de datos
3. Revisar los logs de error
4. Crear un issue en el repositorio
