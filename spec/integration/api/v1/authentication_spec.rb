# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Authentication', type: :request do
  let(:user) { create(:user, password: 'password123') }
  let(:inactive_user) { create(:user, :inactive, password: 'password123') }
  let(:unconfirmed_user) { create(:user, :unconfirmed, password: 'password123') }
  let(:admin_user) { create(:user, :admin, password: 'password123') }
  
  let(:valid_credentials) do
    {
      email: user.email,
      password: 'password123',
      remember_me: false
    }
  end
  
  let(:invalid_credentials) do
    {
      email: user.email,
      password: 'wrongpassword',
      remember_me: false
    }
  end
  
  let(:valid_headers) do
    {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
  
  describe 'POST /api/v1/auth/sign_in' do
    context 'con credenciales válidas' do
      before { post '/api/v1/auth/sign_in', params: valid_credentials.to_json, headers: valid_headers }
      
      it 'devuelve un token de autenticación' do
        expect(response).to have_http_status(:ok)
        expect(json_response[:auth_token]).to be_present
        expect(response.headers['Authorization']).to be_present
      end
      
      it 'devuelve los datos del usuario' do
        expect(json_response[:user][:id]).to eq(user.id)
        expect(json_response[:user][:email]).to eq(user.email)
      end
      
      it 'no incluye información sensible' do
        expect(json_response[:user]).not_to have_key(:password_digest)
        expect(json_response[:user]).not_to have_key(:reset_password_token)
      end
    end
    
    context 'con credenciales inválidas' do
      before { post '/api/v1/auth/sign_in', params: invalid_credentials.to_json, headers: valid_headers }
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('Correo electrónico o contraseña inválidos')
      end
    end
    
    context 'con usuario inactivo' do
      before do
        inactive_user # Crea el usuario inactivo
        post '/api/v1/auth/sign_in', 
             params: { email: inactive_user.email, password: 'password123' }.to_json, 
             headers: valid_headers
      end
      
      it 'devuelve un error de cuenta inactiva' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('Su cuenta ha sido desactivada. Contacte al administrador.')
      end
    end
    
    context 'con usuario no confirmado' do
      before do
        unconfirmed_user # Crea el usuario no confirmado
        post '/api/v1/auth/sign_in', 
             params: { email: unconfirmed_user.email, password: 'password123' }.to_json, 
             headers: valid_headers
      end
      
      it 'devuelve un error de cuenta no confirmada' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to include('Debe confirmar su correo electrónico')
      end
    end
    
    context 'con opción remember_me' do
      let(:remember_me_credentials) { valid_credentials.merge(remember_me: true) }
      
      it 'establece un token con expiración extendida' do
        post '/api/v1/auth/sign_in', params: remember_me_credentials.to_json, headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        token = response.headers['Authorization'].split(' ').last
        decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base).first
        
        # Verifica que el token expira en 30 días (en segundos)
        expect(decoded_token['exp']).to be_within(1.minute).of(30.days.from_now.to_i)
      end
    end
  end
  
  describe 'DELETE /api/v1/auth/sign_out' do
    let!(:token) { generate_token_for_user(user) }
    
    before do
      delete '/api/v1/auth/sign_out', 
             headers: { 'Authorization' => "Bearer #{token}" }
    end
    
    it 'cierra la sesión del usuario' do
      expect(response).to have_http_status(:no_content)
      
      # Intenta acceder a un recurso protegido después de cerrar sesión
      get '/api/v1/users/me', headers: { 'Authorization' => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'POST /api/v1/auth/password' do
    context 'solicitud de restablecimiento de contraseña' do
      it 'envía instrucciones de restablecimiento' do
        expect {
          post '/api/v1/auth/password', 
               params: { email: user.email }.to_json, 
               headers: valid_headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        
        expect(response).to have_http_status(:ok)
        expect(json_response[:message]).to eq('Se han enviado instrucciones para restablecer su contraseña a su correo electrónico.')
      end
      
      it 'no revela si el correo no existe' do
        post '/api/v1/auth/password', 
             params: { email: 'nonexistent@example.com' }.to_json, 
             headers: valid_headers
        
        expect(response).to have_http_status(:ok) # Por seguridad, no revelamos si el correo existe
        expect(json_response[:message]).to eq('Si su dirección de correo electrónico existe en nuestro sistema, recibirá un correo con instrucciones para restablecer su contraseña.')
      end
    end
    
    context 'cambio de contraseña con token válido' do
      let(:reset_token) { user.send_reset_password_instructions }
      
      it 'permite cambiar la contraseña' do
        put '/api/v1/auth/password', 
            params: { 
              reset_password_token: reset_token,
              password: 'newpassword123',
              password_confirmation: 'newpassword123'
            }.to_json,
            headers: valid_headers
        
        expect(response).to have_http_status(:ok)
        expect(json_response[:message]).to eq('Su contraseña se ha cambiado correctamente. Ahora puede iniciar sesión con su nueva contraseña.')
        
        # Verifica que la contraseña se haya cambiado
        user.reload
        expect(user.valid_password?('newpassword123')).to be_truthy
      end
    end
    
    context 'con token inválido' do
      it 'devuelve un error' do
        put '/api/v1/auth/password', 
            params: { 
              reset_password_token: 'invalid_token',
              password: 'newpassword123',
              password_confirmation: 'newpassword123'
            }.to_json,
            headers: valid_headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to include('El token de restablecimiento no es válido o ha expirado')
      end
    end
  end
  
  describe 'GET /api/v1/auth/validate_token' do
    context 'con token válido' do
      let!(:token) { generate_token_for_user(user) }
      
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'Authorization' => "Bearer #{token}" }
      end
      
      it 'valida el token y devuelve el usuario' do
        expect(response).to have_http_status(:ok)
        expect(json_response[:user][:id]).to eq(user.id)
        expect(json_response[:user][:email]).to eq(user.email)
      end
    end
    
    context 'con token inválido' do
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'Authorization' => 'Bearer invalid_token' }
      end
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('No autorizado')
      end
    end
    
    context 'con token expirado' do
      let!(:expired_token) { generate_expired_token_for_user(user) }
      
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'Authorization' => "Bearer #{expired_token}" }
      end
      
      it 'devuelve un error de token expirado' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('Sesión expirada. Por favor, inicie sesión nuevamente.')
      end
    end
  end
  
  describe 'POST /api/v1/auth/refresh_token' do
    let!(:token) { generate_token_for_user(user) }
    
    context 'con token válido' do
      it 'refresca el token' do
        # Espera 1 segundo para asegurar que el nuevo token sea diferente
        sleep(1)
        
        post '/api/v1/auth/refresh_token', 
             headers: { 'Authorization' => "Bearer #{token}" }
        
        expect(response).to have_http_status(:ok)
        expect(json_response[:auth_token]).to be_present
        expect(json_response[:auth_token]).not_to eq(token)
        
        # Verifica que el nuevo token sea válido
        new_token = json_response[:auth_token]
        get '/api/v1/users/me', 
            headers: { 'Authorization' => "Bearer #{new_token}" }
        expect(response).to have_http_status(:ok)
      end
    end
    
    context 'con token inválido' do
      before do
        post '/api/v1/auth/refresh_token', 
             headers: { 'Authorization' => 'Bearer invalid_token' }
      end
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response[:error]).to eq('No autorizado')
      end
    end
  end
  
  describe 'Protección contra fuerza bruta' do
    let(:attempts_limit) { 5 }
    
    it 'bloquea la cuenta después de varios intentos fallidos' do
      # Realiza varios intentos fallidos
      (attempts_limit + 1).times do |i|
        post '/api/v1/auth/sign_in', 
             params: { email: user.email, password: 'wrongpassword' }.to_json, 
             headers: valid_headers
             
        if i < attempts_limit
          expect(response).to have_http_status(:unauthorized)
        else
          # Después del límite, la cuenta debería estar bloqueada
          expect(response).to have_http_status(:too_many_requests)
          expect(json_response[:error]).to include('Demasiados intentos fallidos. Su cuenta ha sido bloqueada temporalmente.')
        end
      end
      
      # Verifica que el usuario esté bloqueado
      user.reload
      expect(user.access_locked?).to be_truthy
      
      # Intento de inicio de sesión con la contraseña correcta debe fallar
      post '/api/v1/auth/sign_in', 
           params: { email: user.email, password: 'password123' }.to_json, 
           headers: valid_headers
      
      expect(response).to have_http_status(:too_many_requests)
    end
  end
  
  describe 'Protección CSRF' do
    it 'requiere token CSRF para acciones que modifican datos' do
      # Deshabilitar la protección CSRF para esta prueba
      allow_any_instance_of(Api::V1::AuthController).to receive(:protect_against_forgery?).and_return(true)
      
      post '/api/v1/auth/sign_in', 
           params: valid_credentials.to_json, 
           headers: valid_headers
      
      # Debería fallar con error de token CSRF faltante
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to include('Token CSRF no válido')
    end
  end
  
  private
  
  def generate_token_for_user(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
  
  def generate_expired_token_for_user(user)
    payload = {
      user_id: user.id,
      email: user.email,
      exp: 1.hour.ago.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
  
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
