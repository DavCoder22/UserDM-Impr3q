require 'pg'
require 'json'

module Database
  class Connection
    def self.connect
      @connection ||= PG.connect(
        dbname: ENV['DB_NAME'] || 'auth_db',
        user: ENV['DB_USER'] || 'postgres',
        password: ENV['DB_PASSWORD'] || 'postgres',
        host: ENV['DB_HOST'] || 'db',
        port: ENV['DB_PORT'] || 5432
      )
    end

    def self.query(sql, params = [])
      connect.exec_params(sql, params)
    end

    def self.transaction
      connect.transaction do |conn|
        yield conn
      end
    end

    def self.migrate
      connect.exec(File.read('db/migrations/001_create_schema.sql'))
    rescue PG::Error => e
      puts "Migration error: #{e.message}"
      raise
    end
  end
end
