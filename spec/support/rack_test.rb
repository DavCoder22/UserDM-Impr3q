module RSpecMixin
  include Rack::Test::Methods
  
  def app
    # Esto se sobrescribirá en cada archivo de especificaciones
    raise 'Debes definir el método app en tu prueba o especificar la aplicación Rack'
  end
  
  def json_response
    JSON.parse(last_response.body, symbolize_names: true)
  end
  
  def auth_headers(user, session = nil)
    token = session&.token || JWTAuth.generate_access_token(user.id, user.rol, session&.id)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include RSpecMixin, type: :request
end
