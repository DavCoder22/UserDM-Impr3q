# Configuración del entorno de pruebas para Sinatra
ENV['RACK_ENV'] = 'test'
ENV['DB_HOST'] ||= 'localhost'
ENV['DB_PORT'] ||= '5432'
ENV['DB_NAME'] ||= 'auth_db_test'
ENV['DB_USER'] ||= 'postgres'
ENV['DB_PASSWORD'] ||= 'postgres'
ENV['JWT_SECRET'] ||= 'test-secret-key-1234567890'
ENV['JWT_ACCESS_TOKEN_EXP'] ||= '3600'
ENV['JWT_REFRESH_TOKEN_EXP'] ||= '2592000'

# Configurar logging para pruebas
ENV['LOG_LEVEL'] = 'error' 