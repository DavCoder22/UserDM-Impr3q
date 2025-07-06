# frozen_string_literal: true

# Configure Rack Attack for rate limiting and blocking
# Docs: https://github.com/rack/rack-attack

class Rack::Attack
  # Configure cache store for Rack::Attack
  Rack::Attack.cache.store = if Rails.env.production?
                               # Use Redis in production
                               Rails.cache
                             else
                               # Use memory store in development/test
                               ActiveSupport::Cache::MemoryStore.new
                             end

  # Throttle all API requests by IP (100rpm/IP)
  throttle('api/ip', limit: 100, period: 1.minute) do |req|
    if req.path.start_with?('/api/')
      req.ip
    end
  end

  # Throttle login attempts by IP (5 per minute)
  throttle('logins/ip', limit: 5, period: 1.minute) do |req|
    if req.post? && req.path == '/api/v1/auth/sign_in'
      req.ip
    end
  end

  # Throttle login attempts by email (5 per minute)
  throttle('logins/email', limit: 5, period: 1.minute) do |req|
    if req.post? && req.path == '/api/v1/auth/sign_in' && req.params['email'].present?
      # Normalize the email, using the same logic as your auth logic
      req.params['email'].to_s.downcase.gsub(/\s+/, '')
    end
  end

  # Throttle password reset requests (5 per hour per email)
  throttle('password_resets/email', limit: 5, period: 1.hour) do |req|
    if req.post? && req.path == '/api/v1/auth/password' && req.params['email'].present?
      req.params['email'].to_s.downcase.gsub(/\s+/, '')
    end
  end

  # Block suspicious requests
  blocklist('block suspicious requests') do |req|
    # Block requests containing suspicious patterns
    req.path.include?('/.env') ||
      req.path.include?('wp-admin') ||
      req.path.include?('wp-login') ||
      req.path.include?('phpmyadmin') ||
      req.path.include?('.git/')
  end

  # Custom throttled response
  self.throttled_response = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]

    headers = {
      'RateLimit-Limit' => match_data[:limit].to_s,
      'RateLimit-Remaining' => '0',
      'RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s,
      'Retry-After' => (match_data[:period] - (now % match_data[:period])).to_s,
      'Content-Type' => 'application/json'
    }

    [429, headers, [
      {
        success: false,
        errors: [
          {
            status: '429',
            title: 'Too Many Requests',
            detail: 'Rate limit exceeded. Please try again later.'
          }
        ]
      }.to_json
    ]]
  end

  # Custom blocked response
  self.blocklisted_response = lambda do |_env|
    [403, { 'Content-Type' => 'application/json' }, [
      {
        success: false,
        errors: [
          {
            status: '403',
            title: 'Forbidden',
            detail: 'Your request has been blocked for security reasons.'
          }
        ]
      }.to_json
    ]]
  end
end

# Log blocked events
ActiveSupport::Notifications.subscribe('rack.attack') do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]
  next unless req.env['rack.attack.match_type']

  # Log to Rails log
  Rails.logger.warn do
    [
      "Rack_Attack #{req.env['rack.attack.match_type']}:",
      "path=#{req.path}",
      "method=#{req.request_method}",
      "ip=#{req.ip}",
      "user_agent=#{req.user_agent}",
      "match_type=#{req.env['rack.attack.match_type']}",
      "match_data=#{req.env['rack.attack.match_data']}"
    ].join(' ')
  end

  # Optionally send to error tracking service
  if defined?(Sentry)
    Sentry.with_scope do |scope|
      scope.set_context('rate_limit', {
        path: req.path,
        method: req.request_method,
        ip: req.ip,
        user_agent: req.user_agent,
        match_type: req.env['rack.attack.match_type'],
        match_data: req.env['rack.attack.match_data']
      })
      Sentry.capture_message("Rack::Attack #{req.env['rack.attack.match_type']} triggered")
    end
  end
end
