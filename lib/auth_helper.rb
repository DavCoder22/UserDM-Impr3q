require 'jwt'

module AuthHelper
  class AuthenticationError < StandardError; end
  class TokenExpired < AuthenticationError; end
  class InvalidToken < AuthenticationError; end

  JWT_SECRET = ENV['JWT_SECRET'] || 'your-secret-key'
  JWT_ALGORITHM = 'HS256'
  TOKEN_EXPIRATION = 24 * 60 * 60 # 24 horas en segundos

  def self.generate_token(user_id, role)
    payload = {
      user_id: user_id,
      role: role,
      exp: Time.now.to_i + TOKEN_EXPIRATION
    }
    
    JWT.encode(payload, JWT_SECRET, JWT_ALGORITHM)
  end

  def self.decode_token(token)
    begin
      decoded = JWT.decode(token, JWT_SECRET, true, { algorithm: JWT_ALGORITHM }).first
      HashWithIndifferentAccess.new(decoded)
    rescue JWT::ExpiredSignature
      raise TokenExpired, 'Token has expired'
    rescue JWT::DecodeError
      raise InvalidToken, 'Invalid token'
    end
  end

  def self.authenticate_request(env)
    auth_header = env['HTTP_AUTHORIZATION']
    token = auth_header&.split(' ')&.last
    
    raise AuthenticationError, 'No token provided' unless token
    
    # Verificar si el token está en la lista negra (logout)
    redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://redis:6379/0', password: ENV['REDIS_PASSWORD'])
    if redis.get("blacklist:#{token}")
      raise AuthenticationError, 'Token has been invalidated'
    end
    
    # Decodificar y validar el token
    decoded_token = decode_token(token)
    
    # Agregar información del usuario al entorno de la solicitud
    env['user_id'] = decoded_token[:user_id]
    env['user_role'] = decoded_token[:role]
    
    true
  rescue => e
    raise AuthenticationError, e.message
  end
end
