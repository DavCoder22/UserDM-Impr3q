require 'simplecov'
require 'simplecov-console'
require 'simplecov-lcov'

# Configure SimpleCov for authentication system
SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.lcov_file_name = 'lcov.info'
  c.output_directory = 'coverage'
end

SimpleCov.start 'rails' do
  # Define code groups with priorities
  add_group 'Authentication', %w[
    app/controllers/users
    app/controllers/api/v1/auth
    app/models/user.rb
    app/models/identity.rb
    app/policies/user_policy.rb
    app/serializers/user_serializer.rb
  ]
  
  add_group 'Admin', %w[
    app/controllers/admin
    app/policies/admin
  ]
  
  add_group 'Services', 'app/services'
  add_group 'Mailers', 'app/mailers'
  add_group 'Jobs', 'app/jobs'
  add_group 'Models', 'app/models', &->(src_file) {
    !src_file.filename.include?('user.rb') && !src_file.filename.include?('identity.rb')
  }
  
  # Filter out files that don't need coverage
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  add_filter '/vendor/'
  add_filter '/channels/'
  add_filter '/jobs/'
  add_filter '/mailers/application_mailer.rb'
  add_filter '/models/application_record.rb'
  
  # Configure formatters
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
  
  # Coverage thresholds
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
  
  # Ignore files with too few lines
  add_filter do |source_file|
    source_file.lines.count < 5 || 
    source_file.filename.include?('version.rb') ||
    source_file.filename.include?('schema.rb')
  end
  
  # Track test coverage for authentication-related files
  track_files 'app/controllers/api/v1/auth/**/*.rb'
  track_files 'app/controllers/users/**/*.rb'
  track_files 'app/models/user.rb'
  track_files 'app/policies/**/*.rb'
  
  # Enable branch coverage for critical paths
  enable_coverage :branch
  
  # Configure coverage for branches in authentication flow
  add_group 'Authentication Branches' do |file|
    file.filename.include?('app/controllers/api/v1/auth/') ||
    file.filename.include?('app/models/user.rb')
  end
  
  # Configure coverage for branches in admin flow
  add_group 'Admin Branches' do |file|
    file.filename.include?('app/controllers/admin/')
  end
  
  # Agrupar archivos de prueba
  add_group 'Test Helpers' do |src_file|
    src_file.filename.include?('/spec/') && !src_file.filename.include?('/fixtures/')
  end
  
  # Configuración específica para CI
  if ENV['CI']
    # Ruta relativa al directorio raíz del proyecto
    at_exit do
      puts "\nCoverage report generated to coverage/index.html"
      puts "Coverage: #{SimpleCov.result.covered_percent.round(2)}%"
      
      # Salir con código de error si la cobertura es insuficiente
      unless SimpleCov.result.covered_percent >= 90
        puts "\e[31m¡Cobertura insuficiente! Se requiere al menos 90% de cobertura.\e[0m"
        exit(1)
      end
    end
  end
end

# Iniciar SimpleCov
SimpleCov.start 'rails' do
  # Configuración adicional específica para Rails si es necesario
  track_files 'app/**/*.rb'
  
  # Ignorar archivos de configuración
  add_filter '/config/initializers/'
  add_filter '/config/environments/'
  
  # Ignorar migraciones
  add_filter '/db/migrate/'
  
  # Ignorar archivos específicos
  add_filter '/app/channels/'
  add_filter '/app/jobs/'
  add_filter '/app/mailers/'
  
  # Agregar grupos personalizados
  add_group 'Validators', 'app/validators'
  add_group 'Policies', 'app/policies'
  add_group 'Serializers', 'app/serializers'
  
  # Configuración de ramas de código
  enable_coverage :branch
  
  # Configuración de filtros personalizados
  add_filter do |source_file|
    # Ignorar archivos con menos de 5 líneas de código
    source_file.lines.count < 5
  end
  
  # Configuración específica para CI
  if ENV['CI']
    # Usar caché entre ejecuciones
    cache_dir 'tmp/coverage/.resultset-cache'
    
    # Usar un nombre de conjunto de resultados único para CI
    command_name "CI-#{ENV['GITHUB_RUN_ID'] || 'local'}"
    
    # Configurar el directorio de salida
    coverage_dir 'coverage/ci'
  else
    # Usar un nombre de conjunto de resultados para desarrollo
    command_name 'RSpec'
    
    # Configurar el directorio de salida para desarrollo
    coverage_dir 'coverage/rspec'
  end
end
