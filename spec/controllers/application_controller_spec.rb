# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Crea un controlador anónimo para probar ApplicationController
  controller do
    def index
      render json: { message: 'Hello World' }
    end
    
    def test_authenticate_user!
      authenticate_user!
      render json: { message: 'Authenticated' }
    end
    
    def test_current_user
      render json: { user: current_user&.as_json }
    end
    
    def test_authorize_admin
      authorize_admin
      render json: { message: 'Authorized' }
    end
    
    def test_authorize_self_or_admin
      user = User.find(params[:id])
      authorize_self_or_admin(user)
      render json: { message: 'Authorized' }
    end
  end
  
  before do
    # Define rutas para las acciones del controlador de prueba
    routes.draw do
      get 'test_authenticate' => 'anonymous#test_authenticate_user!'
      get 'test_current_user' => 'anonymous#test_current_user'
      get 'test_admin' => 'anonymous#test_authorize_admin'
      get 'test_self_or_admin/:id' => 'anonymous#test_authorize_self_or_admin'
      get 'index' => 'anonymous#index'
    end
  end
  
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let!(:session) { create(:session, user: user) }
  let!(:admin_session) { create(:session, user: admin) }
  
  describe 'autenticación' do
    context 'sin token de autenticación' do
      it 'devuelve un error de no autorizado' do
        get :test_authenticate
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'No autorizado')
      end
    end
    
    context 'con token de autenticación válido' do
      before do
        request.headers['Authorization'] = "Bearer #{session.token}"
      end
      
      it 'permite el acceso' do
        get :test_authenticate
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('message' => 'Authenticated')
      end
      
      it 'establece current_user' do
        get :test_current_user
        expect(response).to have_http_status(:ok)
        expect(json_response['user']['id']).to eq(user.id)
      end
    end
    
    context 'con token expirado' do
      let!(:expired_session) { create(:session, user: user, expires_at: 1.day.ago) }
      
      before do
        request.headers['Authorization'] = "Bearer #{expired_session.token}"
      end
      
      it 'devuelve un error de sesión expirada' do
        get :test_authenticate
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Sesión expirada')
      end
    end
  end
  
  describe 'autorización de administrador' do
    context 'usuario normal' do
      before do
        request.headers['Authorization'] = "Bearer #{session.token}"
      end
      
      it 'deniega el acceso' do
        get :test_admin
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'administrador' do
      before do
        request.headers['Authorization'] = "Bearer #{admin_session.token}"
      end
      
      it 'permite el acceso' do
        get :test_admin
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('message' => 'Authorized')
      end
    end
  end
  
  describe 'autorización de propietario o administrador' do
    let(:other_user) { create(:user) }
    let!(:other_session) { create(:session, user: other_user) }
    
    context 'usuario normal accediendo a su propio recurso' do
      before do
        request.headers['Authorization'] = "Bearer #{session.token}"
      end
      
      it 'permite el acceso' do
        get :test_authorize_self_or_admin, params: { id: user.id }
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('message' => 'Authorized')
      end
    end
    
    context 'usuario normal accediendo a recurso de otro usuario' do
      before do
        request.headers['Authorization'] = "Bearer #{session.token}"
      end
      
      it 'deniega el acceso' do
        get :test_authorize_self_or_admin, params: { id: other_user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
    
    context 'administrador accediendo a recurso de otro usuario' do
      before do
        request.headers['Authorization'] = "Bearer #{admin_session.token}"
      end
      
      it 'permite el acceso' do
        get :test_authorize_self_or_admin, params: { id: user.id }
        expect(response).to have_http_status(:ok)
        expect(json_response).to include('message' => 'Authorized')
      end
    end
  end
  
  describe 'manejo de excepciones' do
    controller do
      def test_not_found
        raise ActiveRecord::RecordNotFound
      end
      
      def test_parameter_missing
        raise ActionController::ParameterMissing.new(:param)
      end
      
      def test_unauthorized
        raise Pundit::NotAuthorizedError
      end
    end
    
    before do
      routes.draw do
        get 'test_not_found' => 'anonymous#test_not_found'
        get 'test_parameter_missing' => 'anonymous#test_parameter_missing'
        get 'test_unauthorized' => 'anonymous#test_unauthorized'
      end
      
      request.headers['Authorization'] = "Bearer #{session.token}"
    end
    
    it 'maneja ActiveRecord::RecordNotFound' do
      get :test_not_found
      expect(response).to have_http_status(:not_found)
      expect(json_response).to include('error' => 'Recurso no encontrado')
    end
    
    it 'maneja ActionController::ParameterMissing' do
      get :test_parameter_missing
      expect(response).to have_http_status(:bad_request)
      expect(json_response).to include('error' => 'Parámetro requerido no encontrado: param')
    end
    
    it 'maneja Pundit::NotAuthorizedError' do
      get :test_unauthorized
      expect(response).to have_http_status(:forbidden)
      expect(json_response).to include('error' => 'No autorizado')
    end
  end
  
  describe 'protección CSRF' do
    before do
      # Deshabilitar la protección CSRF para la prueba
      allow(controller).to receive(:protect_against_forgery?).and_return(true)
    end
    
    context 'sin token CSRF' do
      it 'devuelve un error' do
        post :index
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'Solicitud no válida')
      end
    end
    
    context 'con token CSRF inválido' do
      before do
        request.headers['X-CSRF-Token'] = 'invalid_token'
      end
      
      it 'devuelve un error' do
        post :index
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to include('error' => 'Solicitud no válida')
      end
    end
  end
  
  describe 'protección XSS' do
    it 'configura los encabezados de seguridad' do
      get :index
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['X-Frame-Options']).to eq('SAMEORIGIN')
      expect(response.headers['X-XSS-Protection']).to eq('1; mode=block')
      expect(response.headers['Content-Security-Policy']).to be_present
    end
  end
  
  describe 'formato de respuesta' do
    it 'devuelve JSON por defecto' do
      get :index
      expect(response.content_type).to include('application/json')
    end
    
    context 'con formato HTML solicitado' do
      before { request.headers['Accept'] = 'text/html' }
      
      it 'devuelve un error' do
        get :index
        expect(response).to have_http_status(:not_acceptable)
        expect(json_response).to include('error' => 'Formato no soportado')
      end
    end
  end
  
  describe 'manejo de parámetros' do
    controller do
      def test_params
        params.require(:user).permit(:name, :email)
        render json: { message: 'Parámetros válidos' }
      end
    end
    
    before do
      routes.draw do
        post 'test_params' => 'anonymous#test_params'
      end
      
      request.headers['Authorization'] = "Bearer #{session.token}"
    end
    
    it 'permite parámetros fuertes correctamente' do
      post :test_params, params: { user: { name: 'Test', email: 'test@example.com' } }
      expect(response).to have_http_status(:ok)
    end
    
    it 'filtra parámetros no permitidos' do
      post :test_params, params: { 
        user: { 
          name: 'Test', 
          email: 'test@example.com',
          admin: true  # Parámetro no permitido
        } 
      }
      
      expect(controller.params[:user][:admin]).to be_nil
    end
  end
end
