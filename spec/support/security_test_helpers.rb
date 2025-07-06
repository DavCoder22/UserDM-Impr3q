# frozen_string_literal: true

module SecurityTestHelpers
  # Helper methods for testing security headers
  module Headers
    def expect_security_headers(response)
      # Standard security headers
      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['X-Download-Options']).to eq('noopen')
      expect(response.headers['X-Permitted-Cross-Domain-Policies']).to eq('none')
      
      # HSTS header in non-test environments
      unless Rails.env.test?
        expect(response.headers['Strict-Transport-Security']).to include('max-age=')
      end
    end
    
    def expect_cors_headers(response, methods: nil, headers: nil)
      expect(response.headers['Access-Control-Allow-Origin']).to be_present
      expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
      
      if methods
        allowed_methods = response.headers['Access-Control-Allow-Methods']
        methods.each do |method|
          expect(allowed_methods).to include(method)
        end
      end
      
      if headers
        allowed_headers = response.headers['Access-Control-Allow-Headers']
        headers.each do |header|
          expect(allowed_headers).to include(header)
        end
      end
    end
    
    def expect_rate_limit_headers(response, limit: nil, remaining: nil, reset: nil)
      expect(response.headers['X-RateLimit-Limit']).to be_present
      expect(response.headers['X-RateLimit-Remaining']).to be_present
      expect(response.headers['X-RateLimit-Reset']).to be_present
      expect(response.headers['Retry-After']).to be_present
      
      if limit
        expect(response.headers['X-RateLimit-Limit'].to_i).to eq(limit)
      end
      
      if remaining
        expect(response.headers['X-RateLimit-Remaining'].to_i).to eq(remaining)
      end
      
      if reset
        expect(response.headers['X-RateLimit-Reset'].to_i).to be_within(1).of(Time.now.to_i + reset)
      end
    end
  end
  
  # Helper methods for testing rate limiting
  module RateLimiting
    def exceed_rate_limit(path, method: :get, params: {}, headers: {}, limit: 100)
      (limit + 1).times do
        send(method, path, params: params, headers: headers)
      end
      response
    end
    
    def exceed_login_attempts(email: 'test@example.com', limit: 5)
      (limit + 1).times do |i|
        post '/api/v1/auth/sign_in', 
             params: { email: email, password: 'wrong' }.to_json, 
             headers: { 'Content-Type' => 'application/json' }
      end
      response
    end
  end
  
  # Helper methods for testing CORS
  module Cors
    def cors_preflight_request(path, origin: 'http://localhost:3000', method: 'GET', headers: [])
      process(
        :options,
        path,
        headers: {
          'Origin' => origin,
          'Access-Control-Request-Method' => method,
          'Access-Control-Request-Headers' => headers.join(','),
          'Content-Type' => 'application/json'
        }
      )
    end
  end
end

# Include helpers in request specs
RSpec.configure do |config|
  config.include SecurityTestHelpers::Headers, type: :request
  config.include SecurityTestHelpers::RateLimiting, type: :request
  config.include SecurityTestHelpers::Cors, type: :request
  
  # Include in feature specs if needed
  config.include SecurityTestHelpers::Headers, type: :feature
  config.include SecurityTestHelpers::RateLimiting, type: :feature
  config.include SecurityTestHelpers::Cors, type: :feature
end
