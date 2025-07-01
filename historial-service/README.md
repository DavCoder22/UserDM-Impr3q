# Servicio de Historial (History Service)

Microservicio encargado de registrar y consultar el historial de acciones de los usuarios en el sistema, incluyendo inicios de sesión, cambios de perfil, actividades y eventos personalizados.

## 🚀 Características

- Registro centralizado de eventos del sistema
- Consulta de historial con múltiples filtros
- Soporte para eventos personalizados
- Integración con servicio de autenticación
- Base de datos MySQL para almacenamiento de eventos
- API GraphQL para consultas flexibles

## 🛠️ Tecnologías

- **Ruby** 3.x
- **Sinatra** como framework web
- **GraphQL** para consultas flexibles
- **Sequel** como ORM
- **MySQL** para almacenamiento de eventos
- **JWT** para autenticación
- **RSpec** para pruebas

## 📦 Requisitos

- Ruby 3.x
- MySQL 8.0+
- Servicio de autenticación funcionando
- Bundler

## 🔧 Configuración

1. Clonar el repositorio
2. Instalar dependencias:

   ```bash
   bundle install
   ```

3. Copiar el archivo de ejemplo de variables de entorno:

   ```bash
   cp .env.example .env
   ```

4. Configurar las variables de entorno en `.env`
5. Ejecutar migraciones:

   ```bash
   ruby config/database.rb migrate
   ```

6. Iniciar el servidor:

   ```bash
   ruby app.rb -p 4569
   ```

## 🔑 Variables de Entorno

```env
# Entorno
RACK_ENV=development

# MySQL (Eventos)
DB_MYSQL_HOST=localhost
DB_MYSQL_PORT=3306
DB_MYSQL_NAME=historial_service_development
DB_MYSQL_USER=root
DB_MYSQL_PASSWORD=root

# Autenticación
AUTH_SERVICE_URL=http://localhost:4567  # URL del auth-service
JWT_PUBLIC_KEY=clave_publica_jwt  # Debe coincidir con la clave pública del auth-service

# Servidor
HOST=0.0.0.0
PORT=4569
```

## 📡 API GraphQL

El servicio expone un único endpoint GraphQL en `/graphql` que permite realizar consultas y mutaciones.

### Autenticación

Todas las peticiones requieren un token JWT válido en el header:

```http
Authorization: Bearer <token>
```

### Consultas Disponibles

#### Obtener eventos con filtros

```graphql
query {
  events(
    userId: ID
    eventType: String
    startDate: String
    endDate: String
    limit: Int
    offset: Int
  ) {
    id
    userId
    eventType
    description
    metadata
    createdAt
  }
}
```

#### Obtener un evento por ID

```graphql
query {
  event(id: "event_id_here") {
    id
    userId
    eventType
    description
    metadata
    createdAt
  }
}
```

### Mutaciones Disponibles

#### Crear un nuevo evento

```graphql
mutation {
  createEvent(
    userId: ID!
    eventType: String!
    description: String!
    metadata: JSON
  ) {
    id
    eventType
    description
    createdAt
  }
}
```

## 🗄️ Modelo de Datos

### Tabla: events

| Columna       | Tipo         | Descripción                              |
|---------------|--------------|------------------------------------------|
| id            | UUID         | Identificador único del evento           |
| user_id       | Integer      | ID del usuario relacionado                |
| event_type    | String       | Tipo de evento (ej: login, profile_update)|
| description   | Text         | Descripción legible del evento           |
| metadata      | JSON         | Datos adicionales del evento (opcional)  |
| created_at    | DateTime     | Fecha y hora de creación                 |
| updated_at    | DateTime     | Última actualización                     |

## 🧪 Pruebas

Para ejecutar las pruebas:

```bash
# Instalar dependencias de desarrollo
bundle install --with test

# Ejecutar pruebas
bundle exec rspec
```

## 🚀 Despliegue

El servicio está diseñado para ser desplegado en contenedores Docker o directamente en un servidor con Ruby instalado.

### Con Docker

```bash
docker-compose up --build
```

## 🔒 Seguridad

- Todas las consultas requieren autenticación mediante JWT
- Los usuarios solo pueden consultar sus propios eventos a menos que sean administradores
- Se validan y sanitizan todas las entradas
- Las conexiones a la base de datos usan SSL en producción

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `id` | SERIAL | Identificador primario |
| `email` | TEXT | Correo del usuario propietario del evento |
| `event_type` | TEXT | Tipo de evento (purchase, login, update_profile, etc.) |
| `payload` | JSONB | Cuerpo del evento en JSON arbitrario |
| `created_at` | TIMESTAMP | Fecha de creación |

## Esquema GraphQL (SDL)
```graphql
type Event {
  id: ID!
  email: String!
  event_type: String!
  payload: JSON
  created_at: String!
}

type Query {
  events(email: String!, type: String): [Event!]!
  event(id: ID!): Event
}

type Mutation {
  createEvent(email: String!, event_type: String!, payload: JSON): Event!
}
```

---

## Variables de entorno
| Variable         | Descripción                               |
|------------------|-------------------------------------------|
| `DB_HOST`        | Host de PostgreSQL                        |
| `DB_PORT`        | Puerto                                   |
| `DB_NAME`        | Base de datos                             |
| `DB_USER`        | Usuario                                   |
| `DB_PASSWORD`    | Contraseña                                |
| `PORT`           | Puerto del servicio                       |
| `JWT_PUBLIC_KEY` | Clave pública para verificar los tokens   |

## Instalación y ejecución
```bash
bundle install
ruby app.rb
```

---

## Flujo de Autorización
1. El cliente añade un `Authorization: Bearer <jwt>` obtenido de `auth-service`.
2. Middleware valida la firma y expiración del token.
3. Si es válido, permite registrar o leer el historial.
