require 'spec_helper'

RSpec.describe JWTAuth do
  let(:user_id) { SecureRandom.uuid }
  let(:role) { 'cliente' }
  let(:session_id) { SecureRandom.uuid }
  let(:expiration) { 3600 } # 1 hora
  
  before do
    # Limpiar Redis antes de cada prueba
    $redis.flushdb
  end
  
  describe '.generate_access_token' do
    it 'genera un token JWT válido' do
      token = described_class.generate_access_token(user_id, role, session_id)
      expect(token).to be_a(String)
      
      # Verificar que el token se puede decodificar
      payload = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
      expect(payload['sub']).to eq(user_id)
      expect(payload['role']).to eq(role)
      expect(payload['jti']).to be_present
      expect(payload['exp']).to be > Time.now.to_i
    end
  end
  
  describe '.generate_refresh_token' do
    it 'genera un token de actualización' do
      token = described_class.generate_refresh_token(user_id, session_id)
      expect(token).to be_a(String)
      
      # Verificar que el token se puede decodificar
      payload = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
      expect(payload['sub']).to eq(user_id)
      expect(payload['jti']).to be_present
      expect(payload['exp']).to be > (Time.now + 29.days).to_i # Debe ser mayor a 29 días
    end
  end
  
  describe '.decode_token' do
    let(:token) { described_class.generate_access_token(user_id, role, session_id) }
    
    it 'decodifica un token válido' do
      payload = described_class.decode_token(token)
      expect(payload).to be_a(Hash)
      expect(payload['sub']).to eq(user_id)
      expect(payload['role']).to eq(role)
    end
    
    it 'lanza una excepción con un token inválido' do
      invalid_token = 'invalid.token.here'
      expect { described_class.decode_token(invalid_token) }.to raise_error(JWT::DecodeError)
    end
    
    it 'lanza una excepción con un token expirado' do
      expired_token = JWT.encode(
        { 
          sub: user_id, 
          role: role,
          jti: SecureRandom.uuid,
          exp: 1.hour.ago.to_i
        },
        ENV['JWT_SECRET'],
        'HS256'
      )
      
      expect { described_class.decode_token(expired_token) }.to raise_error(JWT::ExpiredSignature)
    end
  end
  
  describe '.blacklist_token' do
    it 'agrega un token a la lista negra' do
      jti = SecureRandom.uuid
      exp = 1.hour.from_now.to_i
      
      described_class.blacklist_token(jti, exp)
      
      # Verificar que el jti está en Redis
      expect($redis.exists?("blacklist:#{jti}")).to be true
      # Verificar que el TTL es aproximadamente el tiempo de expiración
      ttl = $redis.ttl("blacklist:#{jti}")
      expect(ttl).to be_within(5).of(exp - Time.now.to_i)
    end
  end
  
  describe '.blacklisted?' do
    it 'retorna true si el token está en la lista negra' do
      jti = SecureRandom.uuid
      exp = 1.hour.from_now.to_i
      $redis.setex("blacklist:#{jti}", exp - Time.now.to_i, 1)
      
      expect(described_class.blacklisted?(jti)).to be true
    end
    
    it 'retorna false si el token no está en la lista negra' do
      jti = SecureRandom.uuid
      expect(described_class.blacklisted?(jti)).to be false
    end
  end
  
  describe '.verify_token' do
    it 'verifica un token válido' do
      token = described_class.generate_access_token(user_id, role, session_id)
      payload = described_class.verify_token(token)
      
      expect(payload).to be_a(Hash)
      expect(payload['sub']).to eq(user_id)
      expect(payload['role']).to eq(role)
    end
    
    it 'lanza una excepción para un token revocado' do
      token = described_class.generate_access_token(user_id, role, session_id)
      payload = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: 'HS256' }).first
      
      # Agregar a la lista negra
      described_class.blacklist_token(payload['jti'], payload['exp'])
      
      expect { described_class.verify_token(token) }.to raise_error(JWT::DecodeError, 'Token revocado')
    end
  end
  
  describe '.extract_jti' do
    it 'extrae el jti de un token' do
      jti = SecureRandom.uuid
      token = JWT.encode(
        { 
          sub: user_id, 
          role: role,
          jti: jti,
          exp: 1.hour.from_now.to_i 
        },
        ENV['JWT_SECRET'],
        'HS256'
      )
      
      expect(described_class.extract_jti(token)).to eq(jti)
    end
  end
end
