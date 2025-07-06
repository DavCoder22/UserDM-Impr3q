# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sessions', type: :request do
  describe 'POST /api/v1/auth/sign_in' do
    let!(:user) { create(:user, password: 'password') }
    
    context 'con credenciales válidas' do
      before do
        post '/api/v1/auth/sign_in', 
          params: { 
            email: user.email, 
            password: 'password' 
          },
          headers: { 'Content-Type' => 'application/json' }
      end
      
      it 'devuelve un token de acceso' do
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('token')
      end
      
      it 'devuelve información del usuario' do
        expect(json_response['user']).to include(
          'id' => user.id,
          'email' => user.email,
          'nombre' => user.nombre,
          'apellido' => user.apellido,
          'rol' => user.rol
        )
      end
    end
    
    context 'con credenciales inválidas' do
      before do
        post '/api/v1/auth/sign_in', 
          params: { 
            email: user.email, 
            password: 'wrong_password' 
          },
          headers: { 'Content-Type' => 'application/json' }
      end
      
      it 'devuelve un error de autenticación' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Credenciales inválidas')
      end
    end
    
    context 'con usuario inactivo' do
      let!(:inactive_user) { create(:user, :inactive, password: 'password') }
      
      before do
        post '/api/v1/auth/sign_in', 
          params: { 
            email: inactive_user.email, 
            password: 'password' 
          },
          headers: { 'Content-Type' => 'application/json' }
      end
      
      it 'devuelve un error de cuenta inactiva' do
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Cuenta inactiva')
      end
    end
  end
  
  describe 'DELETE /api/v1/auth/sign_out' do
    let!(:user) { create(:user, password: 'password') }
    let!(:session) { create(:session, user: user) }
    
    before do
      delete '/api/v1/auth/sign_out', 
        headers: auth_headers(user, session)
    end
    
    it 'cierra la sesión correctamente' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to include('message' => 'Sesión cerrada correctamente')
    end
    
    it 'invalida el token de la sesión' do
      get '/api/v1/auth/validate_token', 
        headers: auth_headers(user, session)
      
      expect(response).to have_http_status(:unauthorized)
    end
  end
  
  describe 'GET /api/v1/auth/validate_token' do
    let!(:user) { create(:user) }
    let!(:session) { create(:session, user: user) }
    
    before do
      get '/api/v1/auth/validate_token', 
        headers: auth_headers(user, session)
    end
    
    it 'valida el token correctamente' do
      expect(response).to have_http_status(:ok)
      expect(json_response).to include('valid' => true)
    end
    
    it 'devuelve información del usuario' do
      expect(json_response['user']).to include(
        'id' => user.id,
        'email' => user.email,
        'nombre' => user.nombre,
        'apellido' => user.apellido,
        'rol' => user.rol
      )
    end
  end
end
