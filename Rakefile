require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'bundler/gem_tasks'

# Tarea para ejecutar las pruebas de RSpec
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = '--color --format documentation'
end

# Tarea para preparar la base de datos de pruebas
task :setup_test_db do
  require 'dotenv'
  Dotenv.load('.env.test')
  
  db_config = {
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    dbname: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  }
  
  # Crear la base de datos si no existe
  begin
    conn = PG.connect(db_config.merge(dbname: 'postgres'))
    conn.exec("CREATE DATABASE #{db_config[:db_name]}")
    puts "Base de datos de prueba creada: #{db_config[:db_name]}"
  rescue PG::DuplicateDatabase => e
    puts "La base de datos #{db_config[:db_name]} ya existe"
  rescue PG::Error => e
    puts "Error al crear la base de datos: #{e.message}"
  ensure
    conn&.close
  end
  
  # Ejecutar migraciones
  puts "Ejecutando migraciones..."
  system('bundle exec ruby db/migrate.rb')
end

# Tarea predeterminada
task default: :spec

# Tarea para limpiar la base de datos de pruebas
task :clean_test_db do
  require 'dotenv'
  Dotenv.load('.env.test')
  
  db_config = {
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    dbname: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  }
  
  begin
    conn = PG.connect(db_config.merge(dbname: 'postgres'))
    conn.exec("DROP DATABASE IF EXISTS #{db_config[:db_name]}")
    puts "Base de datos de prueba eliminada: #{db_config[:db_name]}"
  rescue PG::Error => e
    puts "Error al eliminar la base de datos: #{e.message}"
  ensure
    conn&.close
  end
end

# Tarea para reiniciar la base de datos de pruebas
task :reset_test_db => [:clean_test_db, :setup_test_db] do
  puts "Base de datos de prueba reiniciada"
end

# Tarea para ejecutar RuboCop
RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['**/*.rb']
  task.fail_on_error = false
  task.requires << 'rubocop-rspec'
  task.requires << 'rubocop-performance'
  task.requires << 'rubocop-rails'
end

# Tarea para verificar la cobertura de pruebas
RSpec::Core::RakeTask.new(:coverage) do |t|
  ENV['COVERAGE'] = 'true'
  t.pattern = 'spec/**/*_spec.rb'
end

# Tarea para ejecutar todas las verificaciones
task :check do
  Rake::Task['rubocop'].invoke
  Rake::Task['spec'].invoke
end

# Tarea para iniciar la consola de desarrollo
task :console do
  require 'irb'
  require_relative 'app'
  ARGV.clear
  IRB.start
end

# Tarea para ejecutar migraciones
task :migrate do
  require 'dotenv'
  Dotenv.load('.env')
  
  puts "Ejecutando migraciones..."
  system('bundle exec ruby db/migrate.rb')
end

# Tarea para ver el estado de la base de datos
task :db_status do
  require 'dotenv'
  Dotenv.load('.env')
  
  db_config = {
    host: ENV['DB_HOST'],
    port: ENV['DB_PORT'],
    dbname: ENV['DB_NAME'],
    user: ENV['DB_USER'],
    password: ENV['DB_PASSWORD']
  }
  
  begin
    conn = PG.connect(db_config)
    result = conn.exec("SELECT datname FROM pg_database WHERE datistemplate = false;")
    puts "Bases de datos disponibles:"
    result.each { |row| puts "- #{row['datname']}" }
    
    puts "\nTablas en #{db_config[:dbname]}:"
    result = conn.exec("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';")
    result.each { |row| puts "- #{row['table_name']}" }
  rescue PG::Error => e
    puts "Error al conectar a la base de datos: #{e.message}"
  ensure
    conn&.close
  end
end

# Tarea para verificar la configuración del entorno
task :check_env do
  require 'dotenv'
  Dotenv.load
  
  puts "=== Configuración del entorno ==="
  puts "RACK_ENV: #{ENV['RACK_ENV'] || 'No definido'}"
  puts "DB_HOST: #{ENV['DB_HOST'] || 'No definido'}"
  puts "DB_NAME: #{ENV['DB_NAME'] || 'No definido'}"
  puts "JWT_SECRET: #{ENV['JWT_SECRET'] ? 'Definido' : 'No definido'}"
  puts "REDIS_URL: #{ENV['REDIS_URL'] || 'No definido'}"
  puts "==============================="
end
