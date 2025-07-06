require 'spec_helper'
require 'bcrypt'

RSpec.describe 'AuthRegisterService' do
  include Rack::Test::Methods

  # Configuración de la conexión a la base de datos
  def db_connection
    @db_connection ||= begin
      PG.connect(
        host: ENV['DB_HOST'] || 'db',
        port: ENV['DB_PORT'] || 5432,
        dbname: ENV['DB_NAME'] || 'auth_db_test',
        user: ENV['DB_USER'] || 'postgres',
        password: ENV['DB_PASSWORD'] || 'postgres'
      )
    end
  end

  describe 'POST /register' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          nombre: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          rol: 'cliente',
          telefono: '1234567890'
        }
      end

      it 'creates a new user' do
        expect {
          post '/register', valid_params.to_json, { 'CONTENT_TYPE' => 'application/json' }
        }.to change { 
          db_connection.exec('SELECT COUNT(*) FROM users').first['count'].to_i 
        }.by(1)

        expect(last_response.status).to eq(201)
        response = JSON.parse(last_response.body)
        expect(response['message']).to eq('User registered successfully')
        expect(response['user']['email']).to eq(valid_params[:email])
        expect(response['user']['rol']).to eq(valid_params[:rol])
        expect(response).to have_key('token')
      end
    end

    context 'with missing parameters' do
      it 'returns an error' do
        post '/register', { 
          nombre: 'Test User',
          email: 'test@example.com',
          telefono: '1234567890'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(400)
        response = JSON.parse(last_response.body)
        expect(response['error']).to include('Missing required fields')
      end
    end

    context 'with invalid user type' do
      it 'returns an error' do
        post '/register', { 
          nombre: 'Test User',
          email: 'test@example.com',
          password: 'password123',
          rol: 'invalid_type',
          telefono: '1234567890'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(400)
        response = JSON.parse(last_response.body)
        expect(response['error']).to include("Invalid user type")
      end
    end

    context 'when email already exists' do
      before do
        password_hash = BCrypt::Password.create('password123')
        db_connection.exec_params(
          'INSERT INTO users (nombre, email, password_hash, rol, telefono) VALUES ($1, $2, $3, $4, $5)',
          ['Existing User', 'existing@example.com', password_hash, 'cliente', '1234567890']
        )
      end

      it 'returns an error' do
        post '/register', { 
          nombre: 'Existing User',
          email: 'existing@example.com',
          password: 'password123',
          rol: 'cliente',
          telefono: '1234567890'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(409)
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq('User with this email already exists')
      end
    end
  end
end
