require 'bcrypt'
require 'securerandom'

class User
  attr_reader :id, :email, :nombre, :apellido, :telefono, :rol, :email_verificado,
              :cuenta_activa, :fecha_registro, :ultima_conexion, :reset_password_token,
              :reset_token_expires, :email_verification_token, :email_verification_expires

  def initialize(attributes = {})
    @id = attributes[:id] || SecureRandom.uuid
    @email = attributes[:email]
    @password_hash = attributes[:password_hash]
    @nombre = attributes[:nombre]
    @apellido = attributes[:apellido]
    @telefono = attributes[:telefono]
    @rol = attributes[:rol] || 'cliente'
    @email_verificado = attributes[:email_verificado] || false
    @cuenta_activa = attributes[:cuenta_activa] || true
    @fecha_registro = attributes[:fecha_registro] || Time.now.utc
    @ultima_conexion = attributes[:ultima_conexion]
    @reset_password_token = attributes[:reset_password_token]
    @reset_token_expires = attributes[:reset_token_expires]
    @email_verification_token = attributes[:email_verification_token]
    @email_verification_expires = attributes[:email_verification_expires]
  end

  # Autenticación
  def self.authenticate(db_conn, email, password)
    user = find_by_email(db_conn, email)
    return nil unless user
    return nil unless user.cuenta_activa?
    
    if BCrypt::Password.new(user.password_hash) == password
      user.update_last_login(db_conn)
      user
    else
      nil
    end
  end

  # Encriptar contraseña
  def password=(new_password)
    @password_hash = BCrypt::Password.create(new_password)
  end

  # Verificar contraseña
  def valid_password?(password)
    return false unless @password_hash
    BCrypt::Password.new(@password_hash) == password
  end

  # Generar token de recuperación de contraseña
  def generate_password_reset_token(db_conn)
    @reset_password_token = SecureRandom.urlsafe_base64
    @reset_token_expires = Time.now.utc + 1.hour
    
    db_conn.exec_params(
      'UPDATE users SET reset_password_token = $1, reset_token_expires = $2 WHERE id = $3',
      [@reset_password_token, @reset_token_expires, @id]
    )
    
    @reset_password_token
  end

  # Actualizar último inicio de sesión
  def update_last_login(db_conn)
    @ultima_conexion = Time.now.utc
    db_conn.exec_params(
      'UPDATE users SET ultima_conexion = $1 WHERE id = $2',
      [@ultima_conexion, @id]
    )
  end

  # Verificar si el token de recuperación es válido
  def valid_reset_token?(token, db_conn)
    return false unless @reset_password_token && @reset_token_expires
    
    @reset_password_token == token && 
    @reset_token_expires > Time.now.utc &&
    db_conn.exec_params(
      'SELECT 1 FROM users WHERE id = $1 AND reset_password_token = $2 AND reset_token_expires > NOW()',
      [@id, token]
    ).any?
  end

  # Métodos para persistencia
  def self.find_by_id(db_conn, id)
    result = db_conn.exec_params(
      'SELECT * FROM users WHERE id = $1', [id]
    ).first
    
    return nil unless result
    new_from_result(result)
  end

  def self.find_by_email(db_conn, email)
    result = db_conn.exec_params(
      'SELECT * FROM users WHERE email = $1', [email]
    ).first
    
    return nil unless result
    new_from_result(result)
  end

  def save(db_conn)
    if exists?(db_conn)
      update(db_conn)
    else
      insert(db_conn)
    end
  end

  private

  def self.new_from_result(result)
    new(
      id: result['id'],
      email: result['email'],
      password_hash: result['password_hash'],
      nombre: result['nombre'],
      apellido: result['apellido'],
      telefono: result['telefono'],
      rol: result['rol'],
      email_verificado: result['email_verificado'] == 't',
      cuenta_activa: result['cuenta_activa'] == 't',
      fecha_registro: result['fecha_registro'] ? Time.parse(result['fecha_registro']).utc : nil,
      ultima_conexion: result['ultima_conexion'] ? Time.parse(result['ultima_conexion']).utc : nil,
      reset_password_token: result['reset_password_token'],
      reset_token_expires: result['reset_token_expires'] ? Time.parse(result['reset_token_expires']).utc : nil,
      email_verification_token: result['email_verification_token'],
      email_verification_expires: result['email_verification_expires'] ? Time.parse(result['email_verification_expires']).utc : nil
    )
  end

  def exists?(db_conn)
    result = db_conn.exec_params(
      'SELECT 1 FROM users WHERE id = $1', [@id]
    )
    
    !result.values.empty?
  end

  def insert(db_conn)
    db_conn.exec_params(
      'INSERT INTO users (id, email, password_hash, nombre, apellido, telefono, rol, ' \
      'email_verificado, cuenta_activa, fecha_registro, ultima_conexion, ' \
      'reset_password_token, reset_token_expires, email_verification_token, ' \
      'email_verification_expires) ' \
      'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)',
      [
        @id, @email, @password_hash, @nombre, @apellido, @telefono, @rol,
        @email_verificado, @cuenta_activa, @fecha_registro, @ultima_conexion,
        @reset_password_token, @reset_token_expires, @email_verification_token,
        @email_verification_expires
      ]
    )
  end

  def update(db_conn)
    db_conn.exec_params(
      'UPDATE users SET email = $1, password_hash = $2, nombre = $3, apellido = $4, ' \
      'telefono = $5, rol = $6, email_verificado = $7, cuenta_activa = $8, ' \
      'ultima_conexion = $9, reset_password_token = $10, reset_token_expires = $11, ' \
      'email_verification_token = $12, email_verification_expires = $13 ' \
      'WHERE id = $14',
      [
        @email, @password_hash, @nombre, @apellido, @telefono, @rol,
        @email_verificado, @cuenta_activa, @ultima_conexion, @reset_password_token,
        @reset_token_expires, @email_verification_token, @email_verification_expires,
        @id
      ]
    )
  end
  
  # Método para acceder al password_hash desde fuera de la clase
  def password_hash
    @password_hash
  end
  
  # Método para verificar si la cuenta está activa
  def cuenta_activa?
    @cuenta_activa
  end
end
