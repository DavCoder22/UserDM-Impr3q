require 'jwt'
require 'securerandom'
require 'bcrypt'

module JWTAuth
  class << self
    # Genera un token de acceso JWT
    def generate_access_token(user_id, role, session_id)
      payload = {
        user_id: user_id,
        role: role,
        session_id: session_id,
        type: 'access',
        exp: Time.now.to_i + ENV.fetch('JWT_ACCESS_TOKEN_EXP', 3600).to_i,
        jti: SecureRandom.uuid,
        iat: Time.now.to_i
      }
      JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
    end

    # Genera un token de refresco JWT
    def generate_refresh_token(user_id, session_id)
      payload = {
        user_id: user_id,
        session_id: session_id,
        type: 'refresh',
        exp: Time.now.to_i + ENV.fetch('JWT_REFRESH_TOKEN_EXP', 2_592_000).to_i,
        jti: SecureRandom.uuid,
        iat: Time.now.to_i
      }
      JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
    end

    # Verifica y decodifica un token JWT
    def decode_token(token)
      decoded = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' })
      decoded.first.transform_keys(&:to_sym)
    rescue JWT::DecodeError => e
      { error: "Invalid token: #{e.message}" }
    rescue JWT::ExpiredSignature
      { error: 'Token has expired' }
    end

    # Verifica si un token es válido y no ha sido revocado
    def valid_token?(token, redis_conn)
      return false if token.nil? || token.empty?
      
      begin
        payload = decode_token(token)
        return false if payload[:error]
        
        # Verificar si el token está en la lista negra (logout)
        jti = payload[:jti]
        !redis_conn.get("token:#{jti}")
      rescue => e
        false
      end
    end

    # Invalida un token (logout)
    def invalidate_token(token, redis_conn, expires_in = nil)
      return unless token
      
      begin
        payload = decode_token(token)
        return if payload[:error]
        
        jti = payload[:jti]
        exp = payload[:exp] || (Time.now + 24 * 60 * 60).to_i # 24 horas por defecto
        expires_in ||= exp - Time.now.to_i
        
        # Guardar en Redis que el token está revocado
        redis_conn.setex("token:#{jti}", expires_in, 'revoked')
      rescue => e
        # Log the error but don't fail the request
        puts "Error invalidating token: #{e.message}"
      end
    end
  end
end
