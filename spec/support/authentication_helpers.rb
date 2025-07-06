# frozen_string_literal: true

module AuthenticationHelpers
  # Helper method to sign in a user in request specs
  def sign_in(user = nil, password: 'password123')
    user ||= create(:user, password: password)
    post user_session_path, params: { 
      user: { 
        email: user.email, 
        password: password,
        remember_me: '0'
      } 
    }
    # Follow redirect if there is one
    follow_redirect! if response.status == 302
    user
  end

  # Helper method to sign in a user in feature specs
  def sign_in_with_ui(user = nil, password: 'password123')
    user ||= create(:user, password: password)
    visit new_user_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: password
    click_button 'Log in'
    user
  end

  # Helper method to sign out
  def sign_out
    delete destroy_user_session_path
  end

  # Helper method to sign in as an admin
  def sign_in_as_admin(admin = nil)
    admin ||= create(:user, :admin)
    sign_in(admin)
    admin
  end

  # Helper method to sign in with OAuth
  def sign_in_with_oauth(provider = :github, user: nil)
    OmniAuth.config.test_mode = true
    
    # Create a mock auth hash
    auth_hash = {
      provider: provider.to_s,
      uid: '12345',
      info: {
        email: user&.email || 'oauth@example.com',
        name: user&.name || 'OAuth User',
        image: 'http://example.com/image.jpg'
      },
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token',
        expires_at: Time.zone.now + 1.week.to_i
      }
    }
    
    # Mock the OAuth response
    OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new(auth_hash)
    
    # Visit the OAuth callback
    visit send("user_#{provider}_omniauth_callback_path")
    
    # Return the user if we have one, or find the created user
    user || User.find_by(email: auth_hash[:info][:email])
  end

  # Helper to set JWT token in request headers
  def set_jwt_token(user)
    token = JWT.encode(
      { user_id: user.id, exp: 24.hours.from_now.to_i },
      Rails.application.credentials.secret_key_base
    )
    request.headers['Authorization'] = "Bearer #{token}"
  end

  # Helper to parse JSON responses
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end

  # Helper to confirm email for a user
  def confirm_email(user)
    token = user.send(:set_reset_password_token)
    get user_confirmation_path(confirmation_token: token)
    follow_redirect!
  end

  # Helper to reset password
  def reset_password(user, new_password)
    token = user.send(:set_reset_password_token)
    put user_password_path, params: {
      user: {
        reset_password_token: token,
        password: new_password,
        password_confirmation: new_password
      }
    }
  end

  # Helper to test protected routes
  def test_protected_route(method, path, params = {})
    send(method, path, params: params)
    expect(response).to redirect_to(new_user_session_path)
    
    user = create(:user)
    sign_in(user)
    
    send(method, path, params: params)
    response
  end

  # Helper to test admin protected routes
  def test_admin_protected_route(method, path, params = {})
    user = create(:user)
    sign_in(user)
    
    send(method, path, params: params)
    expect(response).to redirect_to(root_path)
    
    admin = create(:user, :admin)
    sign_in(admin)
    
    send(method, path, params: params)
    response
  end

  # Helper to test rate limiting
  def test_rate_limit(path, limit, method: :get, params: {})
    (1..limit + 1).each do |i|
      send(method, path, params: params)
      if i > limit
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  # Helper to test CSRF protection
  def test_csrf_protection(method, path, params = {})
    # First test with valid CSRF token (should pass)
    send(method, path, params: params, headers: { 'X-CSRF-Token' => 'valid_token' })
    initial_status = response.status
    
    # Then test without CSRF token (should fail)
    reset!
    send(method, path, params: params)
    
    # Return both responses for further assertions
    [initial_status, response.status]
  end

  # Helper to test session timeout
  def test_session_timeout(user = nil)
    user ||= create(:user)
    sign_in(user)
    
    # Test immediately (should be signed in)
    get root_path
    expect(response).to be_successful
    
    # Test after timeout (should be signed out)
    travel (Devise.timeout_in + 1.minute) do
      get root_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  # Helper to test remember me functionality
  def test_remember_me(user = nil)
    user ||= create(:user)
    
    # Sign in with remember me
    post user_session_path, params: {
      user: {
        email: user.email,
        password: 'password123',
        remember_me: '1'
      }
    }
    
    # Get the remember token from cookies
    cookies = response.headers['Set-Cookie']
    remember_token = cookies.match(/remember_user_token=([^;]+)/)[1] rescue nil
    
    # Sign out
    delete destroy_user_session_path
    
    # Set the remember token in cookies
    cookies = { 'remember_user_token' => remember_token }
    
    # Test access with remember token
    get root_path, headers: { 'Cookie' => "remember_user_token=#{remember_token}" }
    
    [response.status, cookies]
  end

  # Helper to test password complexity requirements
  def test_password_complexity(user = nil, password: 'Password123!')
    user ||= build(:user)
    user.password = password
    user.valid?
    user.errors[:password]
  end

  # Helper to test account lockout after failed attempts
  def test_account_lockout(user = nil, max_attempts: 5)
    user ||= create(:user)
    
    # Make max_attempts failed login attempts
    (max_attempts + 1).times do |i|
      post user_session_path, params: {
        user: {
          email: user.email,
          password: 'wrong_password'
        }
      }
    end
    
    # Should be locked out now
    user.reload.access_locked?
  end

  # Helper to test password reset flow
  def test_password_reset_flow(user = nil, new_password: 'NewPassword123!')
    user ||= create(:user)
    
    # Request password reset
    post user_password_path, params: {
      user: {
        email: user.email
      }
    }
    
    # Get the reset token from the email
    reset_email = ActionMailer::Base.deliveries.last
    reset_token = reset_email.body.match(/reset_password_token=([^\"]+)/)[1]
    
    # Reset the password
    put user_password_path, params: {
      user: {
        reset_password_token: reset_token,
        password: new_password,
        password_confirmation: new_password
      }
    }
    
    # Try to log in with new password
    post user_session_path, params: {
      user: {
        email: user.email,
        password: new_password
      }
    }
    
    response.successful?
  end

  # Helper to test email confirmation flow
  def test_email_confirmation_flow(user = nil)
    user ||= create(:user, confirmed_at: nil)
    
    # Request confirmation instructions
    post user_confirmation_path, params: {
      user: {
        email: user.email
      }
    }
    
    # Get the confirmation token from the email
    confirmation_email = ActionMailer::Base.deliveries.last
    confirmation_token = confirmation_email.body.match(/confirmation_token=([^\"]+)/)[1]
    
    # Confirm the email
    get user_confirmation_path(confirmation_token: confirmation_token)
    
    # Check if confirmed
    user.reload.confirmed?
  end

  # Helper to test session fixation protection
  def test_session_fixation_protection
    # Get a session before login
    get root_path
    original_session = request.session_options[:id]
    
    # Sign in
    user = create(:user)
    sign_in(user)
    
    # Get session after login
    get root_path
    new_session = request.session_options[:id]
    
    # Session should have changed
    original_session != new_session
  end

  # Helper to test concurrent session control
  def test_concurrent_session_control(user = nil)
    user ||= create(:user)
    
    # First login
    sign_in(user)
    first_session = request.session_options[:id]
    
    # Second login from different location
    reset!
    sign_in(user)
    second_session = request.session_options[:id]
    
    # First session should be invalidated
    [first_session, second_session]
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
  config.include AuthenticationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :feature
  
  # Add Warden test helpers for controller tests
  config.include Warden::Test::Helpers, type: :request
  config.include Warden::Test::Helpers, type: :system
  config.include Warden::Test::Helpers, type: :feature
  
  # Clean up Warden after each test
  config.after(:each) do
    Warden.test_reset!
  end
end
