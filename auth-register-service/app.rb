require 'sinatra/base'
require 'sinatra/json'
require 'pg'
require 'bcrypt'
require_relative '../lib/jwt_auth'

class AuthRegisterService < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
    set :db, PG.connect(ENV['DATABASE_URL'])
  end

  before do
    content_type :json
  end

  # Health check endpoint
  get '/health' do
    { status: 'ok', service: 'auth-register-service' }.to_json
  end

  # Register new user
  post '/register' do
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)
    
    # Validate required fields
    required_fields = [:nombre, :email, :password, :rol, :telefono]
    missing_fields = required_fields.reject { |field| data.key?(field) }
    
    if missing_fields.any?
      status 400
      return { error: "Missing required fields: #{missing_fields.join(', ')}" }.to_json
    end
    
    # Validate user type
    unless %w[cliente impresor].include?(data[:rol])
      status 400
      return { error: "Invalid user type. Must be 'cliente' or 'impresor'" }.to_json
    end
    
    # Check if user already exists
    existing_user = settings.db.exec_params(
      'SELECT id FROM users WHERE email = $1', [data[:email]]
    ).first
    
    if existing_user
      status 409
      return { error: 'User with this email already exists' }.to_json
    end
    
    # Hash password
    password_hash = BCrypt::Password.create(data[:password])
    
    # Create user in database
    result = settings.db.exec_params(
      'INSERT INTO users (nombre, email, password_hash, rol, telefono) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [data[:nombre], data[:email], password_hash, data[:rol], data[:telefono]]
    )
    
    user_id = result[0]['id']
    
    # Generate JWT token
    token = JWTAuth.generate_token(user_id, data[:user_type])
    
    # Return success response
    status 201
    {
      message: 'User registered successfully',
      user: {
        id: user_id,
        nombre: data[:nombre],
        email: data[:email],
        rol: data[:rol],
        telefono: data[:telefono]
      },
      token: token
    }.to_json
  end
  
  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
