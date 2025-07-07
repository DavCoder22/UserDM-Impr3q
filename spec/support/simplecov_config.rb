require 'simplecov'
require 'simplecov-console'
require 'simplecov-lcov'

# Configuración específica para SimpleCov en Sinatra
SimpleCov.configure do
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
end
