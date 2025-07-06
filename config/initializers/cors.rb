# frozen_string_literal: true

# Configure CORS (Cross-Origin Resource Sharing)
# Docs: https://github.com/cyu/rack-cors

# Allow CORS in all environments, with different settings per environment
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # In development, allow all origins for easier development
      origins '*'
    else
      # In other environments, only allow specific origins
      origins(
        # Staging environment
        ENV['STAGING_FRONTEND_URL'],
        
        # Production frontend
        ENV['PRODUCTION_FRONTEND_URL'],
        
        # Mobile apps
        %r{\Ahttps://([a-z0-9-]+\.)?impr3q\.(com|dev)\z},
        %r{\Ahttps://impr3q\.web\.app\z}
      ).compact # Remove any nil values
    end

      # Configure which resources are accessible
      resource(
        # Match all API endpoints
        '/api/*',
        
        # Allowed HTTP methods
        methods: %i[get post put patch delete options head],
        
        # Allowed request headers
        headers: :any,
        
        # Expose additional response headers to the client
        expose: %w[
          Authorization
          X-Request-Id
          X-Runtime
          X-RateLimit-Limit
          X-RateLimit-Remaining
          X-RateLimit-Reset
          Retry-After
          Link
          Total
          Per-Page
          Content-Type
          Accept
          access-token
          client
          uid
          token-type
          expiry
        ],
        
        # Allow credentials (cookies, HTTP authentication)
        credentials: Rails.env.production?,
        
        # Cache preflight requests for 24 hours (in seconds)
        max_age: 86_400
      )
      
      # Allow access to the GraphQL endpoint (if using GraphQL)
      resource '/graphql',
               headers: :any,
               methods: %i[get post options],
               expose: %w[Authorization X-Request-Id X-Runtime],
               credentials: true,
               max_age: 600
      
      # Allow access to the GraphQL WebSocket endpoint (if using ActionCable)
      resource '/cable',
               headers: :any,
               methods: :any,
               expose: %w[Authorization X-Request-Id X-Runtime],
               credentials: true
    end

    # Allow access to public assets (e.g., images, fonts) from any origin
    allow do
      origins '*'
      resource '/assets/*', headers: :any, methods: :get
      resource '/packs/*', headers: :any, methods: :get
      resource '/uploads/*', headers: :any, methods: :get
      resource '/packs-test/*', headers: :any, methods: :get
      resource '/favicon.ico', headers: :any, methods: :get
    end
  end
end

# Configure ActionCable to allow CORS for WebSockets
if defined?(ActionCable)
  module ActionCable
    module Connection
      class Base
        # Override the origin check to use our CORS configuration
        def self.allow_request_origin?(origin)
          return true if Rails.env.test?
          
          # Get allowed origins from environment or use a default
          allowed_origins = if Rails.env.production?
                              ENV.fetch('ALLOWED_ORIGINS', '').split(',').map(&:strip)
                            else
                              [
                                'http://localhost:3000',
                                'http://127.0.0.1:3000',
                                'http://localhost:4000',
                                'http://127.0.0.1:4000',
                                ENV['STAGING_FRONTEND_URL'],
                                ENV['PRODUCTION_FRONTEND_URL']
                              ].compact
                            end
          
          allowed_origins.include?('*') || allowed_origins.include?(origin)
        end
      end
    end
  end
end

# Configure ActionDispatch to handle CORS preflight requests
Rails.application.config.action_dispatch.default_headers.merge!(
  'Access-Control-Allow-Origin' => Rails.env.production? ? 
    ENV['PRODUCTION_FRONTEND_URL'].to_s : '*',
  'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  'Access-Control-Allow-Headers' => 'Origin, X-Requested-With, Content-Type, Accept, Authorization, X-CSRF-Token, access-token, client, uid, token-type, expiry',
  'Access-Control-Allow-Credentials' => Rails.env.production?.to_s,
  'Access-Control-Max-Age' => '1728000',
  'Access-Control-Expose-Headers' => 'access-token, client, uid, token-type, expiry, Authorization, X-Request-Id, X-Runtime, X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset, Retry-After, Link, Total, Per-Page, Content-Type, Accept'
)

# Add CORS headers to all responses
Rails.application.config.middleware.use Rack::Cors do
  allow do
    origins '*'
    resource '*', 
      headers: :any, 
      methods: [:get, :post, :options, :head],
      expose: ['access-token', 'client', 'uid', 'token-type', 'expiry'],
      max_age: 0,
      credentials: false
  end
end
