require 'rack/test'
require 'rspec'
require 'webmock/rspec'
require 'httparty'
require 'factory_bot'
require 'faker'

# Cargar los archivos de la aplicación
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'auth-service'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'perfil-service'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'historial-service'))

# Configuración de RSpec
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods

  # Configuración de FactoryBot
  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # Limpiar la base de datos entre pruebas
  config.before(:each) do
    # Configuración de limpieza de base de datos si es necesario
  end

  # Configuración de WebMock
  WebMock.disable_net_connect!(allow_localhost: true)
  
  # Configuración de Faker
  Faker::Config.locale = 'es'

  # Configuración de RSpec
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

# Cargar helpers personalizados
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

# Configuración de URLs de los servicios
module TestConfig
  AUTH_SERVICE_URL = 'http://localhost:4567'.freeze
  PERFIL_SERVICE_URL = 'http://localhost:4568'.freeze
  HISTORIAL_SERVICE_URL = 'http://localhost:4569'.freeze
end

# Helpers para las pruebas
module RequestHelpers
  def parsed_response
    JSON.parse(last_response.body)
  rescue JSON::ParserError
    {}
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
