# Pruebas del Sistema de Autenticación

Este directorio contiene las pruebas automatizadas para el sistema de autenticación JWT.

## Estructura del directorio

- `models/`: Pruebas para los modelos de la aplicación
  - `user_spec.rb`: Pruebas para el modelo User
  - `session_spec.rb`: Pruebas para el modelo Session
  
- `controllers/`: Pruebas para los controladores de la API
  - `auth_controller_spec.rb`: Pruebas para los endpoints de autenticación
  
- `integration/`: Pruebas de integración de extremo a extremo
  - `auth_flow_spec.rb`: Pruebas del flujo completo de autenticación
  
- `lib/`: Pruebas para bibliotecas y utilidades
  - `jwt_auth_spec.rb`: Pruebas para el módulo JWT
  
- `factories/`: Definiciones de FactoryBot para crear datos de prueba
  - `user_factory.rb`: Fábricas para usuarios y sesiones
  
- `support/`: Configuraciones de soporte para las pruebas
  - `database_cleaner.rb`: Configuración para limpiar la base de datos
  - `factory_bot.rb`: Configuración de FactoryBot
  - `rack_test.rb`: Configuración para pruebas de controlador

## Cómo ejecutar las pruebas

### Requisitos previos

- Docker y Docker Compose instalados
- Las variables de entorno configuradas en `.env.test`

### Configuración

1. Copia el archivo `.env.example` a `.env.test` y configura las variables de entorno necesarias:

   ```bash
   cp .env.example .env.test
   ```

### Ejecutar todas las pruebas

```bash
docker-compose run --rm web bundle exec rspec
```

### Ejecutar pruebas específicas

Para ejecutar solo las pruebas de un archivo:

```bash
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb
```

Para ejecutar una prueba específica por su descripción:

```bash
docker-compose run --rm web bundle exec rspec spec/models/user_spec.rb:10
```

### Opciones de RSpec

- `--format documentation`: Muestra los nombres de las pruebas mientras se ejecutan
- `--color`: Habilita la salida a color
- `--fail-fast`: Detiene la ejecución en el primer error

## Cobertura de pruebas

Las pruebas cubren los siguientes aspectos:

- Registro de usuarios
- Inicio de sesión
- Cierre de sesión
- Renovación de tokens
- Recuperación de contraseña
- Verificación de tokens
- Validaciones de modelo
- Autorización basada en roles

## Depuración

Para depurar las pruebas, puedes usar `binding.pry` en cualquier parte de tu código:

```ruby
it 'debe hacer algo' do
  # Código de prueba
  binding.pry # La ejecución se detendrá aquí
  # Más código de prueba
end
```

## Mantenimiento de pruebas

- Asegúrate de que cada prueba sea independiente
- Usa fábricas en lugar de fixtures para datos de prueba
- Mantén las pruebas rápidas y enfocadas
- Prueba los casos de éxito y de error
- Sigue el patrón Arrange-Act-Assert (Preparar-Actuar-Afirmar)
