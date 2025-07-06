require 'sinatra/base'
require 'json'
require 'redis'
require_relative '../../lib/auth_helper'

class AuthLogoutService < Sinatra::Base
  configure do
    set :show_exceptions, false
    set :redis, Redis.new(url: ENV['REDIS_URL'] || 'redis://redis:6379/0')
  end

  before do
    content_type :json
  end

  post '/logout' do
    auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header&.split(' ')&.last

    unless token
      status 401
      return { error: 'No authentication token provided' }.to_json
    end

    begin
      # Decode token to get expiration time
      payload = AuthHelper.decode_token(token)
      
      if payload && payload[:exp]
        # Calculate remaining token TTL
        ttl = payload[:exp] - Time.now.to_i
        
        # Only add to blacklist if token is not already expired
        if ttl > 0
          # Add token to Redis blacklist with remaining TTL
          settings.redis.setex("blacklist:#{token}", ttl, '1')
        end
        
        status 200
        { message: 'Successfully logged out' }.to_json
      else
        status 401
        { error: 'Invalid token' }.to_json
      end
    rescue AuthHelper::AuthenticationError => e
      status 401
      { error: 'Invalid token', details: e.message }.to_json
    end
  end

  # Check if a token is blacklisted
  get '/check' do
    token = params[:token]
    
    unless token
      status 400
      return { error: 'Token is required' }.to_json
    end

    # Check if token is in the blacklist
    if settings.redis.exists?("blacklist:#{token}")
      status 200
      { valid: false, message: 'Token has been invalidated' }.to_json
    else
      status 200
      { valid: true, message: 'Token is valid' }.to_json
    end
  end

  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
