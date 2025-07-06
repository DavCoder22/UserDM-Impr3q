# frozen_string_literal: true

module JwtHelpers
  # Generate a valid JWT token for testing
  def generate_jwt_token(user, expires_in: 24.hours, **custom_claims)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + expires_in).to_i,
      sub: 'access',
      scopes: ['user'],
      **custom_claims
    }
    
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end
  
  # Generate an expired JWT token for testing
  def generate_expired_jwt_token(user)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: 1.day.ago.to_i,
      exp: 1.hour.ago.to_i,
      sub: 'access',
      scopes: ['user']
    }
    
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end
  
  # Generate a JWT token with invalid signature
  def generate_invalid_signature_jwt_token(user)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 24.hours).to_i,
      sub: 'access',
      scopes: ['user']
    }
    
    # Use a different secret to generate an invalid signature
    JWT.encode(payload, 'wrong_secret', 'HS256')
  end
  
  # Generate a JWT token with missing required claims
  def generate_malformed_jwt_token
    payload = {
      user_id: 1,
      # Missing required claims like jti, iat, exp
    }
    
    JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
  end
  
  # Set JWT token in request headers
  def set_jwt_headers(token, headers = {})
    headers.merge!(
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    )
  end
  
  # Parse JWT token from response
  def parsed_jwt_token_from_response(response)
    auth_header = response.headers['Authorization']
    return {} unless auth_header
    
    token = auth_header.split(' ').last
    JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256').first
  rescue JWT::DecodeError
    {}
  end
  
  # Test JWT token refresh flow
  def test_jwt_refresh_flow(user)
    # Get initial access token and refresh token
    post '/api/v1/auth/sign_in', params: {
      email: user.email,
      password: 'password123'
    }, as: :json
    
    access_token = response.headers['access-token']
    client = response.headers['client']
    uid = response.headers['uid']
    
    # Wait for token to expire (or use a very short expiry in test)
    sleep 1
    
    # Refresh the token
    post '/api/v1/auth/refresh_token', headers: {
      'access-token' => access_token,
      'client' => client,
      'uid' => uid
    }
    
    {
      original_token: access_token,
      new_token: response.headers['access-token'],
      success: response.successful?
    }
  end
  
  # Test JWT token revocation
  def test_jwt_revocation(user)
    # Sign in to get token
    post '/api/v1/auth/sign_in', params: {
      email: user.email,
      password: 'password123'
    }, as: :json
    
    access_token = response.headers['access-token']
    client = response.headers['client']
    uid = response.headers['uid']
    
    # Sign out to revoke token
    delete '/api/v1/auth/sign_out', headers: {
      'access-token' => access_token,
      'client' => client,
      'uid' => uid
    }
    
    # Try to use the revoked token
    get '/api/v1/auth/validate_token', headers: {
      'access-token' => access_token,
      'client' => client,
      'uid' => uid
    }
    
    {
      sign_out_success: response.successful?,
      validate_after_sign_out: !response.successful?
    }
  end
  
  # Test JWT token with custom claims
  def test_jwt_custom_claims(user, claims = {})
    token = generate_jwt_token(user, **claims)
    
    # Use the token in a request
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    {
      status: response.status,
      body: response.body.present? ? JSON.parse(response.body) : {}
    }
  end
  
  # Test JWT token with different scopes
  def test_jwt_scopes(user, scopes = ['user'])
    token = generate_jwt_token(user, scopes: scopes)
    
    # Try to access a protected resource
    get '/api/v1/admin', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token expiration
  def test_jwt_expiration(user)
    # Generate a token that expires in 1 second
    token = generate_jwt_token(user, expires_in: 1.second)
    
    # First request should work
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    first_status = response.status
    
    # Wait for token to expire
    sleep 2
    
    # Second request should fail
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    second_status = response.status
    
    {
      before_expiry: first_status,
      after_expiry: second_status
    }
  end
  
  # Test JWT token with different algorithms
  def test_jwt_algorithm(user, algorithm = 'HS256')
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 1.hour).to_i,
      sub: 'access'
    }
    
    # Generate token with specified algorithm
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, algorithm)
    
    # Try to use the token
    begin
      get '/api/v1/protected', headers: {
        'Authorization' => "Bearer #{token}"
      }
      { status: response.status, error: nil }
    rescue JWT::IncorrectAlgorithm => e
      { status: 401, error: e.message }
    end
  end
  
  # Test JWT token with tampered payload
  def test_jwt_tampered_token(user)
    # Generate a valid token
    token = generate_jwt_token(user)
    
    # Tamper with the token
    parts = token.split('.')
    payload = JSON.parse(Base64.decode64(parts[1]))
    payload['user_id'] = 9999  # Tamper with user_id
    parts[1] = Base64.strict_encode64(payload.to_json)
    tampered_token = parts.join('.')
    
    # Try to use the tampered token
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{tampered_token}"
    }
    
    response.status
  end
  
  # Test JWT token with missing required claims
  def test_jwt_missing_claims(user)
    # Generate token with missing claims
    payload = { user_id: user.id }
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    # Try to use the token
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with invalid issuer
  def test_jwt_invalid_issuer(user)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 1.hour).to_i,
      iss: 'invalid_issuer',
      sub: 'access'
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with future issued at time
  def test_jwt_future_iat(user)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: (Time.current + 1.hour).to_i,  # Future time
      exp: (Time.current + 2.hours).to_i,
      sub: 'access'
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with nbf (not before) claim
  def test_jwt_nbf_claim(user)
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      nbf: (Time.current + 1.hour).to_i,  # Token not valid yet
      exp: (Time.current + 2.hours).to_i,
      sub: 'access'
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with audience claim
  def test_jwt_aud_claim(user, audience = 'api.example.com')
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 1.hour).to_i,
      aud: audience,
      sub: 'access'
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
    
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with custom headers
  def test_jwt_custom_headers(user, headers = { typ: 'JWT', kid: 'test-key-1' })
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 1.hour).to_i,
      sub: 'access'
    }
    
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256', headers)
    
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}"
    }
    
    response.status
  end
  
  # Test JWT token with encryption
  def test_jwt_encryption(user, encryption_key = Rails.application.credentials.secret_key_base[0..31])
    payload = {
      user_id: user.id,
      jti: SecureRandom.uuid,
      iat: Time.current.to_i,
      exp: (Time.current + 1.hour).to_i,
      sub: 'access',
      sensitive_data: 'secret-info'
    }
    
    # Encrypt the JWT
    key = Base64.decode64(Base64.strict_encode64(encryption_key).ljust(64, '0'))
    token = JWT.encode(payload, key, 'HS256')
    
    # Try to use the encrypted token
    get '/api/v1/protected', headers: {
      'Authorization' => "Bearer #{token}",
      'X-Encrypted' => 'true'
    }
    
    response.status
  end
end

RSpec.configure do |config|
  config.include JwtHelpers, type: :request
  config.include JwtHelpers, type: :system
  config.include JwtHelpers, type: :controller
end
