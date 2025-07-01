require 'bcrypt'
require 'securerandom'
require_relative '../config/database'

class User < Sequel::Model(Database.connect_pg[:usuarios])
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true
  plugin :json_serializer
  
  one_to_many :tokens, key: :usuario_id
  
  def validate
    super
    validates_presence [:nombre, :correo, :password_hash]
    validates_unique :correo
    validates_format(/\A[^@\s]+@[^@\s]+\z/, :correo, message: 'no es un correo válido')
    validates_min_length 6, :password_hash if new? || column_changed?(:password_hash)
  end
  
  # Encriptar la contraseña antes de guardar
  def before_validation
    self.password_hash = BCrypt::Password.create(password_hash) if new? || column_changed?(:password_hash)
    super
  end
  
  # Método para autenticar usuarios
  def self.authenticate(email, password)
    user = where(correo: email).first
    return nil unless user
    
    if BCrypt::Password.new(user.password_hash) == password
      user
    else
      nil
    end
  end
  
  # Método para generar un nuevo token JWT
  def generate_jwt
    payload = {
      user_id: id,
      email: correo,
      role: rol,
      exp: Time.now.to_i + (ENV.fetch('JWT_EXPIRATION', 3600).to_i)
    }
    
    JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
  end
  
  # Método para crear un nuevo token en la base de datos
  def create_token
    token = generate_jwt
    expires_at = Time.now + ENV.fetch('JWT_EXPIRATION', 3600).to_i
    
    Database.connect_mysql[:tokens].insert(
      usuario_id: id,
      jwt: token,
      creado_en: Time.now,
      expira_en: expires_at
    )
    
    token
  end
  
  # Método para invalidar todos los tokens del usuario
  def invalidate_all_tokens
    Database.connect_mysql[:tokens].where(usuario_id: id).delete
  end
  
  # Método para verificar si un token es válido
  def self.valid_token?(token)
    return false unless token
    
    # Verificar en la base de datos
    token_record = Database.connect_mysql[:tokens].where(jwt: token).first
    return false unless token_record
    
    # Verificar si el token ha expirado
    if Time.now > token_record[:expira_en]
      Database.connect_mysql[:tokens].where(id: token_record[:id]).delete
      return false
    end
    
    true
  end
  
  # Método para encontrar un usuario por token
  def self.find_by_token(token)
    return nil unless token
    
    token_record = Database.connect_mysql[:tokens].where(jwt: token).first
    return nil unless token_record
    
    # Verificar si el token ha expirado
    if Time.now > token_record[:expira_en]
      Database.connect_mysql[:tokens].where(id: token_record[:id]).delete
      return nil
    end
    
    self[token_record[:usuario_id]]
  end
  
  # Método para limpiar tokens expirados
  def self.clean_expired_tokens
    Database.connect_mysql[:tokens].where(Sequel.lit('expira_en < ?', Time.now)).delete
  end
end
