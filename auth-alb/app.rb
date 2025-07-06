require 'sinatra/base'
require 'json'
require 'net/http'
require 'uri'
require_relative '../../lib/jwt_auth'

class AuthALB < Sinatra::Base
  configure do
    set :show_exceptions, false
    
    # Service registry
    set :services, {
      register: {
        url: ENV['REGISTER_SERVICE_URL'] || 'http://auth-register-service:3000',
        public: true
      },
      login: {
        url: ENV['LOGIN_SERVICE_URL'] || 'http://auth-login-service:3000',
        public: true
      },
      profile: {
        url: ENV['PROFILE_SERVICE_URL'] || 'http://auth-profile-service:3000',
        public: false
      },
      password: {
        url: ENV['PASSWORD_SERVICE_URL'] || 'http://auth-password-service:3000',
        public_routes: ['/forgot', '/reset']
      },
      logout: {
        url: ENV['LOGOUT_SERVICE_URL'] || 'http://auth-logout-service:3000',
        public: false
      },
      history: {
        url: ENV['HISTORY_SERVICE_URL'] || 'http://auth-history-service:3000',
        public: false
      }
    }
  end

  before do
    content_type :json
    
    # Skip authentication for public routes
    return if public_route?
    
    # Check for authentication token
    auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header&.split(' ')&.last
    
    unless token
      status 401
      return { error: 'Authentication token is required' }.to_json
    end
    
    # Check if token is blacklisted
    if token_blacklisted?(token)
      status 401
      return { error: 'Token has been invalidated' }.to_json
    end
    
    # Verify token and set user context
    begin
      payload = JWTAuth.decode_token(token)
      @current_user_id = payload['user_id']
      @current_user_role = payload['role']
    rescue JWT::DecodeError => e
      status 401
      return { error: 'Invalid or expired token' }.to_json
    end
  end

  # Health check endpoint
  get '/health' do
    { status: 'ok', service: 'auth-alb' }.to_json
  end

  # Route all other requests to the appropriate service
  %w[get post put delete].each do |method|
    send(method, '/*') do
      forward_request(request.request_method, request.path)
    end
  end

  private

  def public_route?
    # Check if the current route is public
    service = find_service(request.path)
    return false unless service
    
    # If the entire service is public
    return true if service[:public]
    
    # Check for specific public routes within a service
    if service[:public_routes]
      service[:public_routes].each do |public_route|
        return true if request.path.start_with?(public_route)
      end
    end
    
    false
  end
  
  def token_blacklisted?(token)
    # Skip blacklist check for login and register routes
    return false if request.path =~ /\/(login|register)/
    
    # Check Redis if the token is blacklisted
    redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://redis:6379/0')
    redis.exists?("blacklist:#{token}")
  rescue => e
    # If Redis is down, log the error but don't block the request
    puts "Redis error: #{e.message}"
    false
  end

  def find_service(path)
    # Match the path to the appropriate service
    settings.services.each do |service_name, config|
      if path.start_with?("/#{service_name}") || 
         (service_name == :register && path == '/register') ||
         (service_name == :login && path == '/login')
        return config
      end
    end
    nil
  end

  def forward_request(method, path)
    service = find_service(path)
    
    unless service
      status 404
      return { error: 'Service not found' }.to_json
    end
    
    # Remove the service prefix from the path
    service_path = path.gsub(/^\/#{service[:url].split('/').last}/, '')
    service_path = '/' if service_path.empty?
    
    # Build the target URL
    target_url = "#{service[:url]}#{service_path}"
    target_uri = URI.parse(target_url)
    
    # Forward the request
    http = Net::HTTP.new(target_uri.host, target_uri.port)
    http.use_ssl = target_uri.scheme == 'https'
    
    # Create request
    request_class = case method.upcase
                    when 'GET' then Net::HTTP::Get
                    when 'POST' then Net::HTTP::Post
                    when 'PUT' then Net::HTTP::Put
                    when 'DELETE' then Net::HTTP::Delete
                    else Net::HTTP::Get
                    end
    
    request = request_class.new(target_uri)
    
    # Copy headers
    request['Content-Type'] = 'application/json'
    request['Accept'] = 'application/json'
    
    # Forward authorization header if present
    if auth_header = env['HTTP_AUTHORIZATION']
      request['Authorization'] = auth_header
    end
    
    # Forward X-Forwarded-For header for IP tracking
    request['X-Forwarded-For'] = request.ip
    
    # Set request body for POST/PUT requests
    if ['POST', 'PUT'].include?(method.upcase) && request.env['rack.input']
      request.body = request.env['rack.input'].read
      request.env['rack.input'].rewind
    end
    
    # Forward query parameters
    request.set_form_data(params) if request.is_a?(Net::HTTP::Post) && !params.empty?
    
    # Send request
    response = http.request(request)
    
    # Return the response
    status response.code.to_i
    response.body
  rescue => e
    status 500
    { error: "Service unavailable: #{e.message}" }.to_json
  end
  
  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
