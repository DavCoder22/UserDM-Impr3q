# frozen_string_literal: true

# Configure security headers using secure_headers gem
# Docs: https://github.com/github/secure_headers

# Default configuration for all responses
SecureHeaders::Configuration.default do |config|
  # Set all headers to their secure defaults
  config.csp = {
    # Default policy configuration
    default_src: %w['self'],
    base_uri: %w['self'],
    block_all_mixed_content: true, # Prevent mixed content
    font_src: %w['self' https: data:],
    form_action: %w['self'],
    frame_ancestors: %w['none'],
    img_src: %w['self' data: https:],
    object_src: %w['none'],
    script_src: %w['self' 'unsafe-inline' 'unsafe-eval' https:],
    style_src: %w['self' 'unsafe-inline' https:],
    connect_src: %w['self' https:],
    child_src: %w['self' blob:],
    frame_src: %w['self'],
    worker_src: %w['self' blob:],
    media_src: %w['self' data:],
    manifest_src: %w['self'],
    upgrade_insecure_requests: !Rails.env.development?,
    report_uri: ENV['CSP_REPORT_URI'].presence
  }

  # Configure HSTS (HTTP Strict Transport Security)
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains; preload"
  
  # Configure X-Frame-Options
  config.x_frame_options = 'DENY'
  
  # Configure X-Content-Type-Options
  config.x_content_type_options = 'nosniff'
  
  # Configure X-XSS-Protection
  config.x_xss_protection = '1; mode=block'
  
  # Configure X-Download-Options
  config.x_download_options = 'noopen'
  
  # Configure X-Permitted-Cross-Domain-Policies
  config.x_permitted_cross_domain_policies = 'none'
  
  # Configure Referrer-Policy
  config.referrer_policy = %w[origin-when-cross-origin strict-origin-when-cross-origin]
  
  # Configure Permissions-Policy
  config.permissions_policy = {
    accelerometer: "'none'",
    ambient_light_sensor: "'none'",
    autoplay: "'self'",
    battery: "'none'",
    camera: "'none'",
    display_capture: "'none'",
    document_domain: "'none'",
    encrypted_media: "'none'",
    fullscreen: "'self'",
    geolocation: "'none'",
    gyroscope: "'none'",
    magnetometer: "'none'",
    microphone: "'none'",
    midi: "'none'",
    payment: "'none'",
    usb: "'none'"
  }
end

# Customize CSP for API endpoints
SecureHeaders::Configuration.override(:api) do |config|
  config.csp = SecureHeaders::OPT_OUT
  config.referrer_policy = %w[no-referrer]
  config.permissions_policy = {}
  
  # Only keep security headers that make sense for APIs
  config.x_frame_options = 'DENY'
  config.x_content_type_options = 'nosniff'
  config.x_xss_protection = '1; mode=block'
  config.x_download_options = 'noopen'
  config.x_permitted_cross_domain_policies = 'none'
  config.hsts = "max-age=#{1.year.to_i}; includeSubDomains; preload"
end

# Apply security headers to all requests
Rails.application.config.middleware.use SecureHeaders::Middleware

# Skip CSRF token for JSON requests
Rails.application.config.action_controller.forgery_protection_origin_check = false

# Configure ActionDispatch to set security headers
Rails.application.config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'DENY',
  'X-Content-Type-Options' => 'nosniff',
  'X-XSS-Protection' => '1; mode=block',
  'X-Download-Options' => 'noopen',
  'X-Permitted-Cross-Domain-Policies' => 'none',
  'Referrer-Policy' => 'strict-origin-when-cross-origin',
  'Permissions-Policy' => [
    "accelerometer 'none'",
    "ambient-light-sensor 'none'",
    "autoplay 'self'",
    "battery 'none'",
    "camera 'none'",
    "display-capture 'none'",
    "document-domain 'none'",
    "encrypted-media 'none'",
    "fullscreen 'self'",
    "geolocation 'none'",
    "gyroscope 'none'",
    "magnetometer 'none'",
    "microphone 'none'",
    "midi 'none'",
    "payment 'none'",
    "usb 'none'"
  ].join(', ')
}
