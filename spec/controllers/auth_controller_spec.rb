require 'spec_helper'

RSpec.describe 'AuthController' do
  let(:db) { $db_connection }
  let(:user) { create(:user, password: 'password123') }
  
  describe 'POST /auth/register' do
    let(:valid_attributes) do
      {
        email: 'test@example.com',
        password: 'secure123',
        nombre: 'Test',
        apellido: 'User',
        telefono: '1234567890',
        rol: 'cliente'
      }
    end
    
    context 'con datos válidos' do
      it 'crea un nuevo usuario' do
        expect {
          post '/auth/register', valid_attributes.to_json, { 'CONTENT_TYPE' => 'application/json' }
        }.to change { db.exec('SELECT COUNT(*) FROM users').first['count'].to_i }.by(1)
        
        expect(last_response.status).to eq(201)
        expect(json_response).to include(
          message: 'Usuario registrado exitosamente',
          user: a_hash_including(
            email: 'test@example.com',
            nombre: 'Test',
            rol: 'cliente'
          )
        )
      end
    end
    
    context 'con datos inválidos' do
      it 'retorna un error si el email ya está en uso' do
        create(:user, email: 'test@example.com')
        
        post '/auth/register', valid_attributes.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(422)
        expect(json_response).to include(
          error: 'Error de validación',
          details: include('email' => include('ya está en uso'))
        )
      end
      
      it 'retorna un error si falta un campo requerido' do
        post '/auth/register', valid_attributes.merge(email: '').to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(422)
        expect(json_response).to include(
          error: 'Error de validación',
          details: include('email' => include('no puede estar vacío'))
        )
      end
    end
  end
  
  describe 'POST /auth/login' do
    before { user } # Crear el usuario antes de las pruebas
    
    context 'con credenciales válidas' do
      it 'inicia sesión y retorna tokens' do
        post '/auth/login', {
          email: user.email,
          password: 'password123'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(200)
        expect(json_response).to include(
          access_token: be_present,
          refresh_token: be_present,
          expires_in: be_present,
          token_type: 'Bearer'
        )
        
        # Verificar que se creó una sesión
        sessions = db.exec_params('SELECT * FROM sessions WHERE user_id = $1', [user.id])
        expect(sessions.ntuples).to eq(1)
      end
    end
    
    context 'con credenciales inválidas' do
      it 'retorna un error' do
        post '/auth/login', {
          email: user.email,
          password: 'wrongpassword'
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
        
        expect(last_response.status).to eq(401)
        expect(json_response).to include(
          error: 'Credenciales inválidas'
        )
      end
    end
  end
  
  describe 'POST /auth/refresh-token' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user_id: user.id) }
    let!(:refresh_token) { JWTAuth.generate_refresh_token(user.id, session.id) }
    
    before do
      # Actualizar la sesión con el refresh token
      db.exec_params(
        'UPDATE sessions SET refresh_token = $1 WHERE id = $2',
        [refresh_token, session.id]
      )
    end
    
    it 'refresca el token de acceso' do
      post '/auth/refresh-token', {
        refresh_token: refresh_token
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      expect(json_response).to include(
        access_token: be_present,
        refresh_token: be_present,
        expires_in: be_present,
        token_type: 'Bearer'
      )
    end
    
    it 'rechaza un token de actualización inválido' do
      post '/auth/refresh-token', {
        refresh_token: 'invalid-token'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(401)
      expect(json_response).to include(
        error: 'Token de actualización inválido o expirado'
      )
    end
  end
  
  describe 'DELETE /auth/logout' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user_id: user.id) }
    let(:access_token) { JWTAuth.generate_access_token(user.id, user.rol, session.id) }
    
    it 'cierra la sesión y revoca el token' do
      delete '/auth/logout', {}, {
        'HTTP_AUTHORIZATION' => "Bearer #{access_token}",
        'CONTENT_TYPE' => 'application/json'
      }
      
      expect(last_response.status).to eq(200)
      expect(json_response).to include(
        message: 'Sesión cerrada exitosamente'
      )
      
      # Verificar que la sesión fue revocada
      result = db.exec_params('SELECT revoked_at FROM sessions WHERE id = $1', [session.id]).first
      expect(result['revoked_at']).not_to be_nil
    end
  end
  
  describe 'POST /auth/forgot-password' do
    let!(:user) { create(:user) }
    
    it 'envía un correo de recuperación' do
      expect {
        post '/auth/forgot-password', {
          email: user.email
        }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      }.to change { db.exec('SELECT COUNT(*) FROM users WHERE reset_password_token IS NOT NULL').first['count'].to_i }.by(1)
      
      expect(last_response.status).to eq(200)
      expect(json_response).to include(
        message: 'Si el correo existe, se ha enviado un enlace de recuperación'
      )
    end
  end
  
  describe 'POST /auth/reset-password' do
    let!(:user) { create(:user) }
    let!(:token) { user.generate_password_reset_token(db) }
    
    it 'restablece la contraseña con un token válido' do
      post '/auth/reset-password', {
        token: token,
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      expect(json_response).to include(
        message: 'Contraseña restablecida exitosamente'
      )
      
      # Verificar que el token se haya invalidado
      db_user = db.exec_params('SELECT * FROM users WHERE id = $1', [user.id]).first
      expect(db_user['reset_password_token']).to be_nil
      
      # Verificar que la contraseña se actualizó
      authenticated = User.authenticate(db, user.email, 'newpassword123')
      expect(authenticated).not_to be_nil
    end
    
    it 'rechaza un token inválido' do
      post '/auth/reset-password', {
        token: 'invalid-token',
        password: 'newpassword123',
        password_confirmation: 'newpassword123'
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(400)
      expect(json_response).to include(
        error: 'Token de restablecimiento inválido o expirado'
      )
    end
  end
  
  describe 'GET /auth/me' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user_id: user.id) }
    let(:access_token) { JWTAuth.generate_access_token(user.id, user.rol, session.id) }
    
    it 'retorna la información del usuario autenticado' do
      get '/auth/me', {}, {
        'HTTP_AUTHORIZATION' => "Bearer #{access_token}",
        'CONTENT_TYPE' => 'application/json'
      }
      
      expect(last_response.status).to eq(200)
      expect(json_response).to include(
        id: user.id,
        email: user.email,
        nombre: user.nombre,
        rol: user.rol
      )
    end
    
    it 'rechaza una solicitud sin token' do
      get '/auth/me', {}, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(401)
      expect(json_response).to include(
        error: 'Token no proporcionado'
      )
    end
  end
end
