require 'spec_helper'
require 'httparty'

RSpec.describe 'Auth Service' do
  include Rack::Test::Methods

  let(:base_url) { TestConfig::AUTH_SERVICE_URL }
  let(:valid_credentials) { build(:login_credentials) }
  let(:invalid_credentials) { { email: 'nonexistent@example.com', password: 'wrong' } }

  before do
    # Limpiar usuarios antes de cada prueba
    USERS.clear if defined?(USERS)
  end

  describe 'POST /register' do
    context 'con credenciales válidas' do
      it 'registra un nuevo usuario' do
        user_attrs = attributes_for(:user)
        
        response = HTTParty.post(
          "#{base_url}/register",
          body: user_attrs.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(response.code).to eq(201)
        expect(JSON.parse(response.body)).to include('message' => 'Usuario registrado exitosamente')
      end

      it 'no permite registrar un usuario con email duplicado' do
        user_attrs = attributes_for(:user)
        
        # Primer registro exitoso
        HTTParty.post(
          "#{base_url}/register",
          body: user_attrs.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
        
        # Intento de registro con el mismo email
        response = HTTParty.post(
          "#{base_url}/register",
          body: user_attrs.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(response.code).to eq(400)
        expect(JSON.parse(response.body)).to include('error' => 'El usuario ya existe')
      end
    end

    context 'con credenciales inválidas' do
      it 'devuelve un error cuando faltan campos requeridos' do
        response = HTTParty.post(
          "#{base_url}/register",
          body: { email: 'test@example.com' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(response.code).to eq(400)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end

  describe 'POST /login' do
    before do
      # Registrar un usuario para pruebas de login
      user_attrs = attributes_for(:user)
      HTTParty.post(
        "#{base_url}/register",
        body: user_attrs.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    context 'con credenciales válidas' do
      it 'inicia sesión exitosamente' do
        response = HTTParty.post(
          "#{base_url}/login",
          body: valid_credentials.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(response.code).to eq(200)
        expect(JSON.parse(response.body)).to include('token')
      end
    end

    context 'con credenciales inválidas' do
      it 'falla con credenciales incorrectas' do
        response = HTTParty.post(
          "#{base_url}/login",
          body: invalid_credentials.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

        expect(response.code).to eq(401)
        expect(JSON.parse(response.body)).to include('error' => 'Credenciales inválidas')
      end
    end
  end

  describe 'Autenticación con JWT' do
    let(:token) do
      # Registrar y loguear usuario para obtener token
      user_attrs = attributes_for(:user)
      HTTParty.post(
        "#{base_url}/register",
        body: user_attrs.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      login_response = HTTParty.post(
        "#{base_url}/login",
        body: { email: user_attrs[:email], password: user_attrs[:password] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      JSON.parse(login_response.body)['token']
    end

    it 'permite acceder a rutas protegidas con token válido' do
      response = HTTParty.get(
        "#{base_url}/protected",
        headers: { 'Authorization' => "Bearer #{token}" }
      )

      expect(response.code).to eq(200)
    end

    it 'rechaza peticiones sin token' do
      response = HTTParty.get("#{base_url}/protected")
      expect(response.code).to eq(401)
    end

    it 'rechaza peticiones con token inválido' do
      response = HTTParty.get(
        "#{base_url}/protected",
        headers: { 'Authorization' => 'Bearer token.invalido' }
      )
      
      expect(response.code).to eq(401)
    end
  end
end
