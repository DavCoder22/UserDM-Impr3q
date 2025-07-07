# Load SimpleCov at the very top for accurate test coverage measurement
require 'simplecov'
require 'simplecov-console'
# require 'simplecov-lcov'  # Comentado temporalmente

# Set environment variables
ENV['RACK_ENV'] ||= 'test'
ENV['RAILS_ENV'] ||= 'test'

# Start SimpleCov before any application code is loaded
SimpleCov.start do
  # Configuración básica
  coverage_dir 'coverage'
  
  # Grupos de archivos para organizar la cobertura
  add_group 'Models', 'models'
  add_group 'Controllers', 'controllers'
  add_group 'Lib', 'lib'
  add_group 'Services', 'services'
  
  # Archivos críticos que deben tener 100% de cobertura
  add_group 'Critical', %w[
    models/user.rb
    models/session.rb
    controllers/auth_controller.rb
    lib/jwt_auth.rb
    lib/auth_helper.rb
  ] do |file|
    minimum_coverage 100
  end
  
  # Ignorar archivos que no necesitan cobertura
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/bin/'
  add_filter '/log/'
  add_filter '/tmp/'
  
  # Ignorar archivos de configuración y migraciones
  add_filter do |source_file|
    source_file.filename.include?('schema.rb') ||
    source_file.filename.include?('migration') ||
    source_file.filename.include?('config.ru') ||
    source_file.filename.include?('Gemfile') ||
    source_file.filename.include?('Rakefile')
  end
  
  # Configurar umbrales de cobertura
  minimum_coverage 80
  minimum_coverage_by_file 70
  maximum_coverage_drop 5
  
  # Habilitar cobertura de ramas para archivos críticos
  enable_coverage :branch
  
  # Configurar formatters
  if ENV['CI']
    # formatter SimpleCov::Formatter::LcovFormatter  # Comentado temporalmente
    formatter SimpleCov::Formatter::Console
  else
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console
      # SimpleCov::Formatter::LcovFormatter  # Comentado temporalmente
    ])
  end
end

# Cargar la aplicación Sinatra
require 'sinatra'
require 'sinatra/base'
require 'rack/test'

# Requerir los modelos y controladores
require_relative '../models/user'
require_relative '../models/session'
require_relative '../controllers/auth_controller'
require_relative '../lib/jwt_auth'
require_relative '../lib/auth_helper'

# Requerir soporte de RSpec
require 'rspec'

# Requerir soporte para pruebas
Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

# Configuración de RSpec
RSpec.configure do |config|
  # Configuración de expectativas
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = [:expect, :should]
  end

  # Configuración de mocks
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end

  # Comportamiento del contexto compartido
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Filtros para ejecutar pruebas específicas
  config.filter_run_when_matching :focus
  config.run_all_when_everything_filtered = true
  config.example_status_persistence_file_path = 'spec/examples.txt'
  
  # Orden de ejecución
  config.order = :random
  Kernel.srand config.seed

  # Deshabilitar monkey patching
  config.disable_monkey_patching!
  config.expose_dsl_globally = false

  # Mostrar advertencias
  config.warnings = true
  
  # Profiling
  config.profile_examples = 10 if ENV['PROFILE']
  
  # Filtros de exclusión
  config.filter_run_excluding :skip => true
  
  # Incluir helpers
  config.include FactoryBot::Syntax::Methods
  config.include Rack::Test::Methods
  
  # Configuración para pruebas de base de datos
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # Configuración para Timecop
  config.around(:each) do |example|
    Timecop.freeze(Time.current) do
      example.run
    end
  end
  
  # Configuración para VCR
  config.around(:each, :vcr) do |example|
    name = example.metadata[:full_description].split("\n").first.gsub(/[^\w\s]/, "").gsub(/\s+/, "_")
    VCR.use_cassette(name, record: :new_episodes, match_requests_on: [:method, :uri, :body]) do
      example.run
    end
  end
  
  # Configuración para FactoryBot
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

# Helpers para pruebas de autenticación
module AuthTestHelpers
  def app
    # Configurar variables de entorno para pruebas
    ENV['RACK_ENV'] = 'test'
    
    # Retornar la aplicación Sinatra
    Sinatra::Application
  end
  
  def json_response
    JSON.parse(last_response.body, symbolize_names: true)
  end
  
  def auth_headers(user, session = nil)
    token = session&.token || JWTAuth.generate_access_token(user.id, user.rol, session&.id)
    { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
  end
  
  def create_and_authenticate_user(role = 'cliente')
    user = create(:user, role: role, password: 'password123')
    session = create(:session, user_id: user.id)
    [user, session]
  end
  
  def create_and_login_user(role = 'cliente')
    user, session = create_and_authenticate_user(role)
    [user, session]
  end
end

RSpec.configure do |config|
  config.include AuthTestHelpers
end
