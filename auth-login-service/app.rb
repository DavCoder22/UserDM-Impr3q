require 'sinatra/base'
require 'json'
require 'bcrypt'
require 'pg'
require_relative '../../lib/auth_helper'
require_relative '../../lib/database'

class AuthLoginService < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  before do
    content_type :json
  end

  post '/login' do
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)

    # Validate required fields
    required_fields = [:email, :password]
    missing_fields = required_fields - data.keys
    
    if missing_fields.any?
      status 400
      return { error: "Missing required fields: #{missing_fields.join(', ')}" }.to_json
    end

    # Find user by email
    result = Database::Connection.query(
      'SELECT * FROM users WHERE email = $1', [data[:email]]
    )

    user = result.first
    
    # Verify password
    if user && BCrypt::Password.new(user['password_hash']) == data[:password]
      # Log login attempt
      Database::Connection.query(
        'INSERT INTO login_history (user_id, ip_address, user_agent) VALUES ($1, $2, $3)',
        [user['id'], request.ip, request.user_agent]
      )

      # Generate JWT token using the new AuthHelper
      token = AuthHelper.generate_token(user['id'], user['rol'])

      # Prepare user data to return
      user_data = {
        id: user['id'],
        email: user['email'],
        nombre: user['nombre'],
        rol: user['rol']
      }

      # Add printer-specific fields if user is a printer
      if user['rol'] == 'impresor'
        user_data.merge!({
          impresoras: user['impresoras'],
          materiales: user['materiales'],
          tiempo_experiencia: user['tiempo_experiencia'],
          calificacion: user['calificacion']
        })
      end

      status 200
      { 
        message: 'Login successful',
        user: user_data,
        token: token 
      }.to_json
    else
      status 401
      { error: 'Invalid email or password' }.to_json
    end
  end

  # Health check endpoint
  get '/health' do
    content_type :json
    
    # Check database connection
    db_status = begin
      conn = PG.connect(
        dbname: ENV['POSTGRES_DB'] || 'auth_db',
        user: ENV['POSTGRES_USER'] || 'postgres',
        password: ENV['POSTGRES_PASSWORD'] || 'postgres',
        host: ENV['POSTGRES_HOST'] || 'db',
        port: ENV['POSTGRES_PORT'] || 5432
      )
      conn.exec('SELECT 1')
      { status: 'ok', database: 'connected' }
    rescue => e
      { status: 'error', database: e.message }
    ensure
      conn&.close
    end

    # Check Redis connection
    redis_status = begin
      redis = Redis.new(
        url: ENV['REDIS_URL'] || 'redis://redis:6379/0',
        password: ENV['REDIS_PASSWORD']
      )
      redis.ping == 'PONG' ? 'connected' : 'error'
      { status: 'ok', redis: 'connected' }
    rescue => e
      { status: 'error', redis: e.message }
    end

    # Combine statuses
    status 200
    {
      service: 'auth-login-service',
      status: 'ok',
      timestamp: Time.now.iso8601,
      dependencies: {
        database: db_status,
        redis: redis_status
      }
    }.to_json
  end

  # Authentication helper for protected routes
  helpers do
    def authenticate!
      begin
        AuthHelper.authenticate_request(request.env)
        @current_user_id = request.env['user_id']
        @current_user_role = request.env['user_role']
      rescue AuthHelper::AuthenticationError => e
        halt 401, { error: 'Authentication failed', details: e.message }.to_json
      end
    end
  end

  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
