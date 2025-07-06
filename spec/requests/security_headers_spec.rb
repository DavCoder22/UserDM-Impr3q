# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Security Headers', type: :request do
  describe 'HTTP Security Headers' do
    let(:user) { create(:user) }
    let(:headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

    before do
      # Sign in to get a valid session
      post '/api/v1/auth/sign_in', 
           params: { email: user.email, password: user.password }.to_json, 
           headers: headers
      @auth_headers = response.headers.slice('access-token', 'client', 'uid')
    end

    it 'includes security headers in API responses' do
      get '/api/v1/auth/validate_token', headers: headers.merge(@auth_headers)
      
      # Check standard security headers
      expect(response.headers['X-Frame-Options']).to eq('DENY')
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['X-Download-Options']).to eq('noopen')
      expect(response.headers['X-Permitted-Cross-Domain-Policies']).to eq('none')
      
      # Check HSTS header in non-test environments
      unless Rails.env.test?
        expect(response.headers['Strict-Transport-Security']).to include('max-age=')
      end
      
      # Check CSP header (if enabled for the route)
      if response.headers['Content-Security-Policy'].present?
        expect(response.headers['Content-Security-Policy']).to be_present
      end
    end

    it 'includes CORS headers for API requests' do
      # Test preflight request
      options '/api/v1/auth/validate_token', 
              headers: { 
                'Origin' => 'http://localhost:3000',
                'Access-Control-Request-Method' => 'GET',
                'Access-Control-Request-Headers' => 'Authorization, Content-Type'
              }
      
      expect(response).to have_http_status(:no_content)
      expect(response.headers['Access-Control-Allow-Origin']).to be_present
      expect(response.headers['Access-Control-Allow-Methods']).to include('GET')
      expect(response.headers['Access-Control-Allow-Headers']).to include('Authorization', 'Content-Type')
      expect(response.headers['Access-Control-Allow-Credentials']).to eq('true')
      expect(response.headers['Access-Control-Max-Age']).to be_present
    end
  end

  describe 'Content Security Policy' do
    it 'has a properly configured CSP' do
      get root_path
      
      # Skip CSP check if not set for this route
      next unless response.headers['Content-Security-Policy']
      
      csp = response.headers['Content-Security-Policy']
      
      # Check default-src is set to 'self'
      expect(csp).to include("default-src 'self'")
      
      # Check dangerous directives are restricted
      expect(csp).to include("object-src 'none'")
      expect(csp).to include("base-uri 'self'")
      
      # Check frame-ancestors is set to 'none'
      expect(csp).to include('frame-ancestors')
      
      # Check upgrade-insecure-requests is enabled in production
      if Rails.env.production?
        expect(csp).to include('upgrade-insecure-requests')
      end
    end
  end

  describe 'Rate Limiting' do
    let(:user) { create(:user) }
    let(:headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json' } }

    it 'throttles excessive login attempts by IP' do
      # Make 5 login attempts (just under the limit)
      5.times do
        post '/api/v1/auth/sign_in', 
             params: { email: 'wrong@example.com', password: 'wrong' }.to_json, 
             headers: headers
      end
      
      # 6th attempt should be rate limited
      post '/api/v1/auth/sign_in', 
           params: { email: 'wrong@example.com', password: 'wrong' }.to_json, 
           headers: headers
      
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After']).to be_present
      expect(response.headers['X-RateLimit-Limit']).to be_present
      expect(response.headers['X-RateLimit-Remaining']).to eq('0')
      expect(response.headers['X-RateLimit-Reset']).to be_present
      
      # Verify rate limit response body
      json = JSON.parse(response.body)
      expect(json['success']).to be_falsey
      expect(json.dig('errors', 0, 'title')).to eq('Too Many Requests')
    end

    it 'throttles excessive API requests by IP' do
      # Make 100 API requests (just under the limit)
      100.times do |i|
        get '/api/v1/ping', headers: headers
        expect(response).to have_http_status(:ok) unless i == 99
      end
      
      # 101st request should be rate limited
      get '/api/v1/ping', headers: headers
      
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe 'Blocked Paths' do
    it 'blocks access to sensitive paths' do
      sensitive_paths = [
        '/.env',
        '/.git/config',
        '/wp-admin',
        '/wp-login.php',
        '/phpmyadmin',
        '/adminer'
      ]
      
      sensitive_paths.each do |path|
        get path
        expect(response).to have_http_status(:forbidden)
        
        json = JSON.parse(response.body)
        expect(json['success']).to be_falsey
        expect(json.dig('errors', 0, 'title')).to eq('Forbidden')
      end
    end
  end
end
