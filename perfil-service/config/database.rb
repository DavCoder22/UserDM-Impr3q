require 'sequel'
require 'dotenv/load'

# Cargar variables de entorno
Dotenv.load

# Configuración de conexión a la base de datos PostgreSQL para perfiles
def connect_db
  Sequel.connect(
    adapter: 'postgres',
    host: ENV.fetch('DB_PG_HOST', 'localhost'),
    port: ENV.fetch('DB_PG_PORT', 5432),
    database: ENV.fetch('DB_PG_NAME', 'perfil_service_development'),
    user: ENV.fetch('DB_PG_USER', 'postgres'),
    password: ENV.fetch('DB_PG_PASSWORD', 'postgres'),
    max_connections: ENV.fetch('DB_POOL', 5).to_i,
    test: true
  )
end

# Configuración para entorno de prueba
def connect_test_db
  Sequel.connect(
    adapter: 'postgres',
    host: ENV.fetch('TEST_DB_PG_HOST', 'localhost'),
    port: ENV.fetch('TEST_DB_PG_PORT', 5432),
    database: ENV.fetch('TEST_DB_PG_NAME', 'perfil_service_test'),
    user: ENV.fetch('TEST_DB_PG_USER', 'postgres'),
    password: ENV.fetch('TEST_DB_PG_PASSWORD', 'postgres')
  )
end

# Establecer la conexión a la base de datos según el entorno
DB = case ENV['RACK_ENV']
      when 'test'
        connect_test_db
      else
        connect_db
      end

# Cargar extensiones de PostgreSQL
DB.extension :pg_json

# Configurar logger
DB.loggers << Logger.new($stdout) if ENV['RACK_ENV'] == 'development'

# Cargar modelos después de configurar la conexión
require_relative '../models/profile'
