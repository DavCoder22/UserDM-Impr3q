-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol VARCHAR(20) NOT NULL CHECK (rol IN ('cliente', 'impresor')),
    telefono VARCHAR(20),
    ubicacion JSONB,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    impresoras VARCHAR(255)[],
    materiales VARCHAR(255)[],
    tiempo_experiencia INTEGER,
    calificacion DECIMAL(3,2),
    historial_cotizaciones UUID[],
    reset_password_token VARCHAR(255),
    reset_token_expires TIMESTAMP
);

-- Create login_history table
CREATE TABLE IF NOT EXISTS login_history (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    login_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT
);

-- Indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_reset_token ON users(reset_password_token) WHERE reset_password_token IS NOT NULL;
CREATE INDEX idx_login_history_user_id ON login_history(user_id);
