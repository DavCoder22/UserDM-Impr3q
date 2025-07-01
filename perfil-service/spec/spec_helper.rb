require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require 'factory_bot'
require 'faker'
require 'database_cleaner/sequel'
require_relative '../app'

# Cargar el entorno de pruebas
ENV['RACK_ENV'] = 'test'

# Configuración de RSpec
RSpec.configure do |config|
  # Activar el soporte para Factory Bot
  config.include FactoryBot::Syntax::Methods
  
  # Configurar Factory Bot
  config.before(:suite) do
    FactoryBot.find_definitions
  end
  
  # Configurar Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
  
  # Limpiar la base de datos antes de cada prueba
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
  
  # Configurar Rack Test
  def app
    Sinatra::Application
  end
  
  # Configurar WebMock
  WebMock.disable_net_connect!(allow_localhost: true)
  
  # Helpers para pruebas
  def json_response
    JSON.parse(last_response.body, symbolize_names: true)
  end
  
  def auth_headers(token)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}", 'CONTENT_TYPE' => 'application/json' }
  end
  
  def create_test_user(id: 1, email: 'test@example.com', role: 'user')
    {
      id: id,
      nombre: 'Test User',
      correo: email,
      rol: role,
      fecha_creacion: Time.now.iso8601
    }
  end
  
  def stub_auth_request(user, status: 200)
    stub_request(:get, "#{ENV['AUTH_SERVICE_URL']}/api/v1/auth/me")
      .with(headers: { 'Authorization' => "Bearer valid_token_#{user[:id]}" })
      .to_return(
        status: status,
        body: user.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end

# Cargar el entorno de la aplicación
require_relative '../config/database'
