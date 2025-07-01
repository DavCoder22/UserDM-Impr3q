require 'jwt'
require_relative '../config/database'

class Token < Sequel::Model(Database.connect_mysql[:tokens])
  many_to_one :user, key: :usuario_id
  
  # Verificar si el token ha expirado
  def expired?
    Time.now > expira_en
  end
  
  # Invalidar este token
  def invalidate
    self.class.where(id: id).delete
  end
  
  # Verificar si el token es válido
  def valid_token?
    !expired?
  end
  
  # Obtener el payload del JWT
  def payload
    return @payload if defined?(@payload)
    
    begin
      @payload = JWT.decode(jwt, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
    rescue JWT::DecodeError, JWT::ExpiredSignature
      @payload = nil
    end
    
    @payload
  end
  
  # Obtener el usuario asociado a este token
  def user
    return @user if defined?(@user)
    
    payload = self.payload
    return nil unless payload && payload['user_id']
    
    @user = User[payload['user_id']]
  end
  
  # Limpiar tokens expirados
  def self.clean_expired
    where(Sequel.lit('expira_en < ?', Time.now)).delete
  end
  
  # Encontrar un token por su valor JWT
  def self.find_by_jwt(token_value)
    return nil unless token_value
    
    token = where(jwt: token_value).first
    return nil unless token && !token.expired?
    
    token
  end
  
  # Crear un nuevo token para un usuario
  def self.create_for_user(user, expires_in: nil)
    expires_in ||= ENV.fetch('JWT_EXPIRATION', 3600).to_i
    expires_at = Time.now + expires_in
    
    payload = {
      user_id: user.id,
      email: user.correo,
      role: user.rol,
      exp: expires_at.to_i
    }
    
    jwt_token = JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
    
    create(
      usuario_id: user.id,
      jwt: jwt_token,
      creado_en: Time.now,
      expira_en: expires_at
    )
  end
end
