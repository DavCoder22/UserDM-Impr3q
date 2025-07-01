require 'sequel'
require 'dotenv/load'
require 'logger'

module Database
  class << self
    def connect_pg
      @pg_db ||= Sequel.connect(
        adapter: 'postgres',
        host: ENV.fetch('DB_PG_HOST', 'localhost'),
        port: ENV.fetch('DB_PG_PORT', 5432),
        database: ENV.fetch('DB_PG_NAME', 'auth_service_development'),
        user: ENV.fetch('DB_PG_USER', 'postgres'),
        password: ENV.fetch('DB_PG_PASSWORD', 'postgres'),
        max_connections: ENV.fetch('DB_PG_POOL', 5).to_i,
        logger: logger
      )
    end

    def connect_mysql
      @mysql_db ||= Sequel.connect(
        adapter: 'mysql2',
        host: ENV.fetch('DB_MYSQL_HOST', 'localhost'),
        port: ENV.fetch('DB_MYSQL_PORT', 3306),
        database: ENV.fetch('DB_MYSQL_NAME', 'auth_tokens_development'),
        user: ENV.fetch('DB_MYSQL_USER', 'root'),
        password: ENV.fetch('DB_MYSQL_PASSWORD', 'root'),
        max_connections: ENV.fetch('DB_MYSQL_POOL', 5).to_i,
        logger: logger
      )
    end

    def logger
      return @logger if @logger
      
      log_dir = File.join(File.dirname(__FILE__), '..', 'log')
      FileUtils.mkdir_p(log_dir) unless Dir.exist?(log_dir)
      
      log_file = File.open(File.join(log_dir, "#{ENV['RACK_ENV']}.log"), 'a+')
      log_file.sync = true
      @logger = Logger.new(log_file)
      @logger.level = Logger::DEBUG if ENV['RACK_ENV'] == 'development'
      @logger
    end

    def migrate
      # Ejecutar migraciones de PostgreSQL (usuarios)
      Sequel.extension :migration
      Sequel::Migrator.run(connect_pg, File.join(File.dirname(__FILE__), '..', 'db', 'migrate_pg'), table: 'pg_schema_migrations')
      
      # Ejecutar migraciones de MySQL (tokens)
      Sequel::Migrator.run(connect_mysql, File.join(File.dirname(__FILE__), '..', 'db', 'migrate_mysql'), table: 'mysql_schema_migrations')
    end
  end
end

# Cargar modelos después de configurar las conexiones
require_relative '../models/user'
require_relative '../models/token'
