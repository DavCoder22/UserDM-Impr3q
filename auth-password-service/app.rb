require 'sinatra/base'
require 'json'
require 'securerandom'
require 'bcrypt'
require_relative '../../lib/auth_helper'
require_relative '../../lib/database'

class AuthPasswordService < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :email_service_url, ENV['EMAIL_SERVICE_URL'] || 'http://email-service:3000'
  end

  before do
    content_type :json
  end

  # Forgot password - send reset token
  post '/forgot' do
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)

    unless data[:email]
      status 400
      return { error: 'Email is required' }.to_json
    end

    # Find user by email
    result = Database::Connection.query(
      'SELECT id, email, nombre FROM users WHERE email = $1', [data[:email]]
    )

    user = result.first
    
    if user
      # Generate reset token (valid for 1 hour)
      reset_token = SecureRandom.hex(32)
      expires_at = Time.now + 3600 # 1 hour from now

      # Store token in database
      Database::Connection.query(
        'UPDATE users SET reset_password_token = $1, reset_token_expires = $2 WHERE id = $3',
        [reset_token, expires_at, user['id']]
      )

      # In a real app, send email with reset link
      # For now, we'll just return the token for testing
      # In production, you would send an email with a link like:
      # "#{ENV['FRONTEND_URL']}/reset-password?token=#{reset_token}"
      
      status 200
      { 
        message: 'If an account with that email exists, a password reset link has been sent',
        # In production, don't return the token in the response
        reset_token: ENV['RACK_ENV'] == 'test' ? reset_token : nil
      }.to_json
    else
      # For security, don't reveal if the email exists
      status 200
      { message: 'If an account with that email exists, a password reset link has been sent' }.to_json
    end
  end

  # Reset password with token
  post '/reset' do
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)

    required_fields = [:token, :new_password]
    missing_fields = required_fields - data.keys
    
    if missing_fields.any?
      status 400
      return { error: "Missing required fields: #{missing_fields.join(', ')}" }.to_json
    end

    # Find user by reset token
    result = Database::Connection.query(
      'SELECT id FROM users WHERE reset_password_token = $1 AND reset_token_expires > NOW()',
      [data[:token]]
    )

    user = result.first

    if user
      # Update password and clear reset token
      password_hash = BCrypt::Password.create(data[:new_password])
      
      Database::Connection.query(
        'UPDATE users SET password_hash = $1, reset_password_token = NULL, reset_token_expires = NULL WHERE id = $2',
        [password_hash, user['id']]
      )

      status 200
      { message: 'Password has been reset successfully' }.to_json
    else
      status 400
      { error: 'Invalid or expired token' }.to_json
    end
  end

  # Change password (requires current password)
  put '/change' do
    auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header&.split(' ')&.last
    
    unless token
      status 401
      return { error: 'Authentication token is required' }.to_json
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)

    begin
      # Autenticar la solicitud
      AuthHelper.authenticate_request(request.env)
      
      # Obtener el ID del usuario del entorno
      user_id = request.env['user_id']
      
      # Get user from database
      user_result = Database::Connection.query(
        'SELECT * FROM users WHERE id = $1', [user_id]
      )
      
      user = user_result.first
      
      unless user
        status 404
        return { error: 'User not found' }.to_json
      end
      
      # Verificar contraseña actual
      unless BCrypt::Password.new(user['password_hash']) == data[:current_password]
        status 401
        return { error: 'Current password is incorrect' }.to_json
      end
      
      # Actualizar contraseña
      password_hash = BCrypt::Password.create(data[:new_password])
      
      Database::Connection.query(
        'UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2',
        [password_hash, user['id']]
      )
      
      status 200
      { message: 'Password updated successfully' }.to_json
      
    rescue AuthHelper::AuthenticationError => e
      status 401
      { error: 'Authentication failed', details: e.message }.to_json
    end
  end

  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
