module ApiHelpers
  def json_response
    JSON.parse(last_response.body)
  end
  
  def auth_headers(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end
  
  def register_user(email: 'test@example.com', password: 'password123', user_type: 'cliente')
    post '/register', { 
      email: email, 
      password: password, 
      user_type: user_type 
    }.to_json, { 'CONTENT_TYPE' => 'application/json' }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
