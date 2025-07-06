require 'spec_helper'

RSpec.describe 'Flujo completo de autenticación', type: :request do
  let(:db) { $db_connection }
  
  describe 'Registro, inicio de sesión y cierre de sesión' do
    let(:user_attributes) do
      {
        email: 'test@example.com',
        password: 'secure123',
        nombre: 'Test',
        apellido: 'User',
        telefono: '1234567890',
        rol: 'cliente'
      }
    end
    
    it 'permite a un usuario registrarse, iniciar sesión y cerrar sesión' do
      # 1. Registro de usuario
      post '/auth/register', user_attributes.to_json, { 'CONTENT_TYPE' => 'application/json' }
      expect(last_response.status).to eq(201)
      
      # Verificar que el usuario se creó en la base de datos
      user = db.exec_params('SELECT * FROM users WHERE email = $1', [user_attributes[:email]]).first
      expect(user).not_to be_nil
      
      # 2. Inicio de sesión
      post '/auth/login', {
        email: user_attributes[:email],
        password: user_attributes[:password]
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      auth_response = json_response
      access_token = auth_response[:access_token]
      refresh_token = auth_response[:refresh_token]
      
      # Verificar que se creó una sesión
      sessions = db.exec_params('SELECT * FROM sessions WHERE user_id = $1', [user['id']])
      expect(sessions.ntuples).to eq(1)
      
      # 3. Acceder a un recurso protegido
      get '/auth/me', {}, {
        'HTTP_AUTHORIZATION' => "Bearer #{access_token}",
        'CONTENT_TYPE' => 'application/json'
      }
      
      expect(last_response.status).to eq(200)
      expect(json_response[:email]).to eq(user_attributes[:email])
      
      # 4. Refrescar el token
      post '/auth/refresh-token', {
        refresh_token: refresh_token
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      new_tokens = json_response
      
      # 5. Cerrar sesión
      delete '/auth/logout', {}, {
        'HTTP_AUTHORIZATION' => "Bearer #{new_tokens[:access_token]}",
        'CONTENT_TYPE' => 'application/json'
      }
      
      expect(last_response.status).to eq(200)
      
      # Verificar que la sesión fue revocada
      sessions = db.exec_params('SELECT * FROM sessions WHERE user_id = $1', [user['id']])
      expect(sessions.ntuples).to eq(1)
      expect(sessions.first['revoked_at']).not_to be_nil
      
      # 6. Intentar usar el token después de cerrar sesión
      get '/auth/me', {}, {
        'HTTP_AUTHORIZATION' => "Bearer #{new_tokens[:access_token]}",
        'CONTENT_TYPE' => 'application/json'
      }
      
      expect(last_response.status).to eq(401)
    end
  end
  
  describe 'Recuperación de contraseña' do
    let!(:user) { create(:user, email: 'recovery@example.com', password: 'oldpassword') }
    
    it 'permite a un usuario recuperar su contraseña' do
      # 1. Solicitar recuperación de contraseña
      post '/auth/forgot-password', {
        email: user.email
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      
      # Obtener el token de restablecimiento de la base de datos
      db_user = db.exec_params('SELECT reset_password_token FROM users WHERE id = $1', [user.id]).first
      reset_token = db_user['reset_password_token']
      expect(reset_token).not_to be_nil
      
      # 2. Restablecer la contraseña
      new_password = 'newsecurepassword123'
      post '/auth/reset-password', {
        token: reset_token,
        password: new_password,
        password_confirmation: new_password
      }.to_json, { 'CONTENT_TYPE' => 'application/json' }
      
      expect(last_response.status).to eq(200)
      
      # 3. Verificar que la contraseña se actualizó
      authenticated = User.authenticate(db, user.email, new_password)
      expect(authenticated).not_to be_nil
      
      # 4. Verificar que el token se invalidó
      db_user = db.exec_params('SELECT reset_password_token FROM users WHERE id = $1', [user.id]).first
      expect(db_user['reset_password_token']).to be_nil
    end
  end
end
