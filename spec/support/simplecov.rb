require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  # Filtros para excluir directorios
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/db/'
  
  # Agrupar por tipo de archivo
  add_group 'Models', 'models'
  add_group 'Controllers', 'controllers'
  add_group 'Lib', 'lib'
  
  # Configuración de salida
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])
  
  # Mínimo de cobertura requerida (80%)
  minimum_coverage 80
  
  # No permitir que la cobertura baje del mínimo
  minimum_coverage_by_file 70
  
  # Excluir archivos de configuración
  add_filter do |source_file|
    source_file.filename.end_with?('config.ru') ||
    source_file.filename.include?('initializers')
  end
end

# Cargar el código de la aplicación después de iniciar SimpleCov
require_relative '../../app'
