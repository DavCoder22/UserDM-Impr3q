require 'pg'

RSpec.configure do |config|
  config.before(:suite) do
    begin
      # Configurar conexión de base de datos para pruebas
      $db_connection = PG.connect(
        host: ENV['DB_HOST'] || 'localhost',
        port: ENV['DB_PORT'] || 5432,
        dbname: ENV['DB_NAME'] || 'auth_db_test',
        user: ENV['DB_USER'] || 'postgres',
        password: ENV['DB_PASSWORD'] || 'postgres'
      )
      
      # Crear tablas de prueba si no existen
      create_test_tables
    rescue PG::ConnectionBad => e
      puts "⚠️  No se pudo conectar a PostgreSQL: #{e.message}"
      puts "   Las pruebas que requieren base de datos fallarán."
      puts "   Asegúrate de que PostgreSQL esté ejecutándose."
      $db_connection = nil
    end
  end
  
  config.after(:suite) do
    $db_connection&.close
  end
  
  private
  
  def create_test_tables
    return unless $db_connection
    
    # Crear tabla de usuarios para pruebas
    $db_connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        nombre VARCHAR(100) NOT NULL,
        apellido VARCHAR(100),
        telefono VARCHAR(20),
        rol VARCHAR(20) NOT NULL CHECK (rol IN ('cliente', 'impresor', 'admin')),
        email_verificado BOOLEAN DEFAULT false,
        cuenta_activa BOOLEAN DEFAULT true,
        fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ultima_conexion TIMESTAMP,
        reset_password_token VARCHAR(255),
        reset_token_expires TIMESTAMP,
        email_verification_token VARCHAR(255),
        email_verification_expires TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
    
    # Crear tabla de sesiones para pruebas
    $db_connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS sessions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        token TEXT,
        refresh_token TEXT,
        ip_address VARCHAR(45),
        user_agent TEXT,
        device_info JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP NOT NULL,
        revoked_at TIMESTAMP,
        last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
    
    # Crear tabla de historial de login para pruebas
    $db_connection.exec(<<~SQL)
      CREATE TABLE IF NOT EXISTS login_history (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        ip_address VARCHAR(45),
        user_agent TEXT,
        success BOOLEAN NOT NULL,
        reason VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
    
    # Crear índices
    $db_connection.exec("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);")
    $db_connection.exec("CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);")
    $db_connection.exec("CREATE INDEX IF NOT EXISTS idx_login_history_user_id ON login_history(user_id);")
  rescue => e
    puts "⚠️  Error al crear tablas de prueba: #{e.message}"
  end
end 