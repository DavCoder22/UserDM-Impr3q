# Load SimpleCov at the very top for accurate test coverage measurement
require 'simplecov'
require 'simplecov-console'
require 'simplecov-lcov'

# Load the Rails environment first to ensure proper coverage tracking
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Set up SimpleCov with our custom configuration
require_relative 'support/simplecov_config'

# Start SimpleCov before any application code is loaded
SimpleCov.start 'rails' do
  # Common configuration that applies to all test suites
  
  # Set up coverage groups for better organization
  add_group 'Authentication', %w[
    app/controllers/api/v1/auth
    app/controllers/users
    app/models/user.rb
    app/models/identity.rb
    app/policies/user_policy.rb
  ]
  
  add_group 'Admin', %w[
    app/controllers/admin
    app/policies/admin
  ]
  
  # Configure formatters based on environment
  if ENV['CI']
    # In CI, use LCOV formatter for code climate
    formatter SimpleCov::Formatter::LcovFormatter
  else
    # Local development: HTML + Console
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::Console,
      SimpleCov::Formatter::LcovFormatter
    ])
  end
  
  # Set coverage thresholds
  minimum_coverage 95
  minimum_coverage_by_file 85
  maximum_coverage_drop 2
  
  # Track specific files that must maintain 100% coverage
  add_group 'Critical Authentication', %w[
    app/controllers/api/v1/auth/sessions_controller.rb
    app/controllers/api/v1/auth/registrations_controller.rb
    app/controllers/api/v1/auth/passwords_controller.rb
  ] do |file|
    minimum_coverage 100
  end
  
  # Enable branch coverage for critical paths
  enable_coverage :branch
  
  # Track test coverage for authentication-related files
  track_files 'app/controllers/api/v1/auth/**/*.rb'
  track_files 'app/controllers/users/**/*.rb'
  track_files 'app/models/user.rb'
  track_files 'app/policies/**/*.rb'
  
  # Ignore files that don't need coverage
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/channels/'
  add_filter '/jobs/'
  add_filter '/mailers/application_mailer.rb'
  add_filter '/models/application_record.rb'
  
  # Ignore files with too few lines or specific patterns
  add_filter do |source_file|
    source_file.lines.count < 5 || 
    source_file.filename.include?('version.rb') ||
    source_file.filename.include?('schema.rb')
  end
  
  # Load custom configuration from simplecov_config.rb
  eval(File.read(File.join(File.dirname(__FILE__), 'support', 'simplecov_config.rb')))
end

# Cargar la aplicación
ENV['RACK_ENV'] ||= 'test'
require_relative '../config/application'

# Requerir soporte de RSpec
require 'rspec/rails'

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
  config.shared_context_metadata_behavior = :trigger_inclusion

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
  
  # Configuración para Sidekiq
  config.before(:each) do |example|
    if example.metadata[:sidekiq] == :fake
      Sidekiq::Testing.fake!
    elsif example.metadata[:sidekiq] == :inline
      Sidekiq::Testing.inline!
    else
      Sidekiq::Testing.fake!
    end
  end
  
  # Configuración para FactoryBot
  config.before(:suite) do
    FactoryBot.find_definitions
  end
  
  # Configuración para Shoulda Matchers
  Shoulda::Matchers.configure do |shoulda_config|
    shoulda_config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
  
  # Configuración para WebMock
  WebMock.disable_net_connect!(allow_localhost: true, allow: ['elasticsearch', 'redis'])
  
  # Configuración para ActionMailer
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end
  
  # Configuración para ActiveJob
  config.around(:each, :job) do |example|
    ActiveJob::Base.queue_adapter = :test
    ActiveJob::Base.queue_adapter.perform_enqueued_at_jobs = true
    example.run
  end
  
  # Configuración para System Tests
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
  
  # Formateador de salida
  config.default_formatter = 'doc' if config.files_to_run.one?
  
  # Configuración de salida detallada
  config.default_formatter = 'RSpec::Core::Formatters::Documentation' if ENV['DETAILED']
  
  # Configuración para pruebas de rendimiento
  config.define_derived_metadata(file_path: %r{/spec/performance/}) do |metadata|
    metadata[:type] = :performance
    metadata[:performance] = true
  end
  
  # Configuración para pruebas de integración
  config.define_derived_metadata(file_path: %r{/spec/integration/}) do |metadata|
    metadata[:type] = :integration
  end
  
  # Configuración para pruebas de sistema
  config.define_derived_metadata(file_path: %r{/spec/system/}) do |metadata|
    metadata[:type] = :system
  end
  
  # Configuración para pruebas de controlador
  config.define_derived_metadata(file_path: %r{/spec/controllers/}) do |metadata|
    metadata[:type] = :controller
  end
  
  # Configuración para pruebas de modelo
  config.define_derived_metadata(file_path: %r{/spec/models/}) do |metadata|
    metadata[:type] = :model
  end
  
  # Configuración para pruebas de servicio
  config.define_derived_metadata(file_path: %r{/spec/services/}) do |metadata|
    metadata[:type] = :service
  end
  
  # Configuración para pruebas de trabajos
  config.define_derived_metadata(file_path: %r{/spec/jobs/}) do |metadata|
    metadata[:type] = :job
  end

  # Perfil de ejemplos lentos
  config.profile_examples = 10

  # Orden de ejecución aleatorio
  config.order = :random
  Kernel.srand config.seed

  # Configuración global para FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Limpiar la base de datos antes de cada suite de pruebas
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  # Limpiar la base de datos antes de cada ejemplo
  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # Configuración para pruebas de controlador
  config.include Rack::Test::Methods
  config.include RSpec::Rails::RequestExampleGroup, type: :request

  # Configuración para pruebas de sistema
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  # Configuración para pruebas de sistema con JavaScript
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end

  # Helpers personalizados
  config.include AuthTestHelpers, type: :request
  config.include JsonHelpers, type: :request

  # Hook después de cada ejemplo para verificar que no haya consultas N+1
  config.after(:each) do
    if example.metadata[:n_plus_one]
      expect { example.run }.not_to make_database_queries
    end
  end

  # Configuración para pruebas con Timecop
  config.around(:each, :freeze_time) do |example|
    frozen_time = example.metadata[:freeze_time] || Time.current
    Timecop.freeze(frozen_time) { example.run }
  end

  # Configuración para pruebas con VCR
  config.around(:each, :vcr) do |example|
    name = example.metadata[:vcr] || example.metadata[:full_description]
    VCR.use_cassette(name, record: :new_episodes) do
      example.call
    end
  end

  # Configuración para pruebas con Sidekiq
  config.around(:each, :sidekiq) do |example|
    Sidekiq::Testing.fake! do
      example.run
    end
  end

  # Configuración para pruebas con WebMock
  config.before(:each, :webmock) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

# Configuración de Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Configuración de FactoryBot
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end

# Configuración de DatabaseCleaner
RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

# Configuración de Timecop para pruebas que involucran tiempo
RSpec.configure do |config|
  config.after(:each) do
    Timecop.return
  end
end

# Configuración de WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Cargar archivos de soporte
support_files = Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].sort
support_files.each { |f| require f }

# Cargar factories
factory_files = Dir[File.join(File.dirname(__FILE__), 'factories', '**', '*.rb')].sort
factory_files.each { |f| require f }

# Helpers para pruebas
module AuthTestHelpers
  def app
    # Configurar variables de entorno para pruebas
    ENV['RACK_ENV'] = 'test'
    ENV['JWT_SECRET'] ||= 'test-secret-key-1234567890'
    ENV['JWT_ACCESS_TOKEN_EXP'] ||= '3600' # 1 hora
    ENV['JWT_REFRESH_TOKEN_EXP'] ||= '2592000' # 30 días
    
    # Cargar la aplicación principal
    require_relative '../app'
    App
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
    token = JWTAuth.generate_access_token(user.id, user.rol, session.id)
    refresh_token = JWTAuth.generate_refresh_token(user.id, session.id)
    
    # Actualizar la sesión con los tokens
    session.update(token: token, refresh_token: refresh_token)
    session.save($db_connection)
    
    [user, session, token, refresh_token]
  end
end

# Incluir helpers en RSpec
RSpec.configure do |config|
  config.include AuthTestHelpers
  
  # Configurar la conexión a la base de datos para los modelos
  config.before(:all) do
    $db_connection = PG.connect(
      host: ENV['DB_HOST'] || 'db',
      port: ENV['DB_PORT'] || 5432,
      dbname: ENV['DB_NAME'] || 'auth_db_test',
      user: ENV['DB_USER'] || 'postgres',
      password: ENV['DB_PASSWORD'] || 'postgres'
    )
  end
  
  config.after(:all) do
    $db_connection&.close
  end
end
