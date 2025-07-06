# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Users', type: :request do
  let!(:admin) { create(:user, :admin, password: 'password') }
  let!(:admin_session) { create(:session, user: admin) }
  
  describe 'GET /api/v1/users' do
    let!(:users) { create_list(:user, 3) }
    
    context 'como administrador' do
      before do
        get '/api/v1/users', 
          headers: auth_headers(admin, admin_session)
      end
      
      it 'devuelve la lista de usuarios' do
        expect(response).to have_http_status(:ok)
        expect(json_response.size).to eq(4) # 3 usuarios + el admin
      end
    end
    
    context 'como usuario no autenticado' do
      before { get '/api/v1/users' }
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
  
  describe 'GET /api/v1/users/:id' do
    let!(:user) { create(:user) }
    
    context 'como administrador' do
      before do
        get "/api/v1/users/#{user.id}", 
          headers: auth_headers(admin, admin_session)
      end
      
      it 'devuelve los detalles del usuario' do
        expect(response).to have_http_status(:ok)
        expect(json_response).to include(
          'id' => user.id,
          'email' => user.email,
          'nombre' => user.nombre,
          'apellido' => user.apellido,
          'rol' => user.rol
        )
      end
    end
    
    context 'intentando ver otro usuario' do
      let!(:regular_user) { create(:user, password: 'password') }
      let!(:user_session) { create(:session, user: regular_user) }
      
      before do
        get "/api/v1/users/#{admin.id}", 
          headers: auth_headers(regular_user, user_session)
      end
      
      it 'devuelve un error de no autorizado' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
  
  describe 'POST /api/v1/users' do
    let(:valid_attributes) do
      {
        nombre: 'Nuevo',
        apellido: 'Usuario',
        email: 'nuevo@example.com',
        password: 'password',
        password_confirmation: 'password',
        telefono: '123456789',
        direccion: 'Calle Falsa 123',
        rol: 'cliente'
      }
    end
    
    context 'con atributos válidos' do
      before do
        post '/api/v1/users', 
          params: { user: valid_attributes }.to_json,
          headers: auth_headers(admin, admin_session).merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'crea un nuevo usuario' do
        expect(response).to have_http_status(:created)
        expect(json_response).to include(
          'email' => 'nuevo@example.com',
          'nombre' => 'Nuevo',
          'apellido' => 'Usuario',
          'rol' => 'cliente'
        )
      end
    end
    
    context 'con atributos inválidos' do
      before do
        post '/api/v1/users', 
          params: { user: valid_attributes.merge(email: '') }.to_json,
          headers: auth_headers(admin, admin_session).merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'devuelve un error de validación' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error')
      end
    end
  end
  
  describe 'PATCH /api/v1/users/:id' do
    let!(:user) { create(:user) }
    
    context 'con atributos válidos' do
      before do
        patch "/api/v1/users/#{user.id}", 
          params: { user: { nombre: 'Nuevo Nombre' } }.to_json,
          headers: auth_headers(admin, admin_session).merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'actualiza el usuario' do
        expect(response).to have_http_status(:ok)
        expect(json_response['nombre']).to eq('Nuevo Nombre')
      end
    end
    
    context 'con atributos inválidos' do
      before do
        patch "/api/v1/users/#{user.id}", 
          params: { user: { email: 'correo-invalido' } }.to_json,
          headers: auth_headers(admin, admin_session).merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'devuelve un error de validación' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error')
      end
    end
  end
  
  describe 'DELETE /api/v1/users/:id' do
    let!(:user) { create(:user) }
    
    context 'como administrador' do
      before do
        delete "/api/v1/users/#{user.id}", 
          headers: auth_headers(admin, admin_session)
      end
      
      it 'elimina el usuario' do
        expect(response).to have_http_status(:no_content)
        expect(User.find_by(id: user.id)).to be_nil
      end
    end
    
    context 'intentando eliminarse a sí mismo' do
      before do
        delete "/api/v1/users/#{admin.id}", 
          headers: auth_headers(admin, admin_session)
      end
      
      it 'devuelve un error' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'No puedes eliminarte a ti mismo')
      end
    end
  end
  
  describe 'POST /api/v1/users/:id/change_password' do
    let!(:user) { create(:user, password: 'old_password') }
    
    context 'con la contraseña actual correcta' do
      before do
        post "/api/v1/users/#{user.id}/change_password", 
          params: { 
            current_password: 'old_password',
            new_password: 'new_password',
            new_password_confirmation: 'new_password'
          }.to_json,
          headers: auth_headers(user, create(:session, user: user))
                 .merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'cambia la contraseña' do
        expect(response).to have_http_status(:ok)
        expect(user.reload.authenticate('new_password')).to be_truthy
      end
    end
    
    context 'con la contraseña actual incorrecta' do
      before do
        post "/api/v1/users/#{user.id}/change_password", 
          params: { 
            current_password: 'wrong_password',
            new_password: 'new_password',
            new_password_confirmation: 'new_password'
          }.to_json,
          headers: auth_headers(user, create(:session, user: user))
                 .merge({ 'Content-Type' => 'application/json' })
      end
      
      it 'devuelve un error' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'Contraseña actual incorrecta')
      end
    end
  end
  
  describe 'POST /api/v1/users/forgot_password' do
    let!(:user) { create(:user) }
    
    before do
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('reset_token')
      post '/api/v1/users/forgot_password', 
        params: { email: user.email }.to_json,
        headers: { 'Content-Type' => 'application/json' }
    end
    
    it 'envía instrucciones para restablecer la contraseña' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to include('message' => 'Se han enviado instrucciones a tu correo electrónico')
      expect(user.reload.reset_password_token).to eq('reset_token')
    end
  end
  
  describe 'POST /api/v1/users/reset_password' do
    let!(:user) { create(:user, :with_reset_password_token) }
    
    before do
      post '/api/v1/users/reset_password', 
        params: { 
          token: user.reset_password_token,
          new_password: 'new_password',
          new_password_confirmation: 'new_password'
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
    end
    
    it 'restablece la contraseña' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to include('message' => 'Contraseña restablecida correctamente')
      expect(user.reload.authenticate('new_password')).to be_truthy
      expect(user.reset_password_token).to be_nil
    end
  end
end
