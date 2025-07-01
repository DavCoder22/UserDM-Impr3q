require 'spec_helper'
require 'httparty'

RSpec.describe 'Perfil Service' do
  include Rack::Test::Methods
  
  let(:base_url) { TestConfig::PERFIL_SERVICE_URL }
  let(:auth_url) { TestConfig::AUTH_SERVICE_URL }
  let(:valid_user) { attributes_for(:user) }
  let(:profile_data) { attributes_for(:profile) }
  
  # Helper para obtener token de autenticación
  def auth_token(user_credentials)
    response = HTTParty.post(
      "#{auth_url}/login",
      body: user_credentials.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    JSON.parse(response.body)['token']
  end
  
  before(:all) do
    # Registrar un usuario para pruebas
    @test_user = attributes_for(:user)
    HTTParty.post(
      "#{auth_url}/register",
      body: @test_user.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    @auth_token = auth_token(email: @test_user[:email], password: @test_user[:password])
  end
  
  describe 'GET /profile' do
    context 'con token válido' do
      before do
        # Crear perfil para el usuario de prueba
        HTTParty.put(
          "#{base_url}/profile",
          body: profile_data.merge(email: @test_user[:email]).to_json,
          headers: { 
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@auth_token}"
          }
        )
      end
      
      it 'obtiene el perfil del usuario autenticado' do
        response = HTTParty.get(
          "#{base_url}/profile",
          headers: { 'Authorization' => "Bearer #{@auth_token}" }
        )
        
        expect(response.code).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response).to include('email' => @test_user[:email])
        expect(json_response).to include('nombre', 'apellido', 'telefono')
      end
    end
    
    context 'sin token' do
      it 'devuelve un error de no autorizado' do
        response = HTTParty.get("#{base_url}/profile")
        expect(response.code).to eq(401)
      end
    end
  end
  
  describe 'PUT /profile' do
    let(:updated_profile) { attributes_for(:profile) }
    
    context 'con datos válidos' do
      it 'actualiza el perfil del usuario' do
        response = HTTParty.put(
          "#{base_url}/profile",
          body: updated_profile.merge(email: @test_user[:email]).to_json,
          headers: { 
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@auth_token}"
          }
        )
        
        expect(response.code).to eq(200)
        json_response = JSON.parse(response.body)
        expect(json_response['nombre']).to eq(updated_profile[:nombre])
        expect(json_response['apellido']).to eq(updated_profile[:apellido])
      end
    end
    
    context 'con datos incompletos' do
      it 'devuelve un error de validación' do
        response = HTTParty.put(
          "#{base_url}/profile",
          body: { email: @test_user[:email], nombre: '' }.to_json,
          headers: { 
            'Content-Type' => 'application/json',
            'Authorization' => "Bearer #{@auth_token}"
          }
        )
        
        expect(response.code).to eq(400)
        expect(JSON.parse(response.body)).to include('error')
      end
    end
  end
  
  describe 'GET /profile/avatar' do
    it 'obtiene la URL del avatar del usuario' do
      # Configurar un avatar para el usuario
      avatar_url = Faker::Avatar.image
      HTTParty.put(
        "#{base_url}/profile",
        body: { email: @test_user[:email], avatar_url: avatar_url }.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      response = HTTParty.get(
        "#{base_url}/profile/avatar",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response).to include('avatar_url' => avatar_url)
    end
  end
  
  describe 'PUT /profile/password' do
    it 'cambia la contraseña del usuario' do
      new_password = 'nueva_contraseña123'
      
      response = HTTParty.put(
        "#{base_url}/profile/password",
        body: { 
          current_password: @test_user[:password],
          new_password: new_password,
          confirm_password: new_password
        }.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)).to include('message')
      
      # Verificar que el login con la nueva contraseña funciona
      login_response = HTTParty.post(
        "#{auth_url}/login",
        body: { email: @test_user[:email], password: new_password }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      expect(login_response.code).to eq(200)
    end
  end
  
  describe 'DELETE /profile' do
    it 'elimina el perfil del usuario' do
      # Crear un usuario temporal para esta prueba
      temp_user = attributes_for(:user)
      HTTParty.post(
        "#{auth_url}/register",
        body: temp_user.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      temp_token = auth_token(email: temp_user[:email], password: temp_user[:password])
      
      # Eliminar el perfil
      response = HTTParty.delete(
        "#{base_url}/profile",
        headers: { 'Authorization' => "Bearer #{temp_token}" }
      )
      
      expect(response.code).to eq(200)
      expect(JSON.parse(response.body)).to include('message')
      
      # Verificar que el usuario no puede iniciar sesión
      login_response = HTTParty.post(
        "#{auth_url}/login",
        body: { email: temp_user[:email], password: temp_user[:password] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      expect(login_response.code).to eq(401)
    end
  end
end
