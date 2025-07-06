# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Authentication', type: :request do
  let!(:user) { create(:user, password: 'password123') }
  let(:valid_credentials) do
    {
      email: user.email,
      password: 'password123'
    }
  end
  let(:invalid_credentials) do
    {
      email: user.email,
      password: 'wrongpassword'
    }
  end

  describe 'POST /api/v1/auth/sign_in' do
    context 'with valid credentials' do
      before { post '/api/v1/auth/sign_in', params: valid_credentials }

      it 'returns a success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the authentication token' do
        expect(json_response[:auth_token]).to be_present
      end

      it 'returns the user data' do
        expect(json_response[:user][:id]).to eq(user.id)
        expect(json_response[:user][:email]).to eq(user.email)
      end

      it 'sets the authorization header' do
        expect(response.headers['Authorization']).to be_present
      end
    end

    context 'with invalid credentials' do
      before { post '/api/v1/auth/sign_in', params: invalid_credentials }

      it 'returns an unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error message' do
        expect(json_response[:error]).to eq('Credenciales inválidas')
      end
    end

    context 'with inactive account' do
      let!(:inactive_user) { create(:user, :inactive, password: 'password123') }
      
      before do
        post '/api/v1/auth/sign_in', params: {
          email: inactive_user.email,
          password: 'password123'
        }
      end

      it 'returns an unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error message' do
        expect(json_response[:error]).to eq('Cuenta inactiva')
      end
    end
  end

  describe 'DELETE /api/v1/auth/sign_out' do
    let!(:session) { create(:session, user: user) }
    
    before do
      delete '/api/v1/auth/sign_out', 
             headers: { 'Authorization' => "Bearer #{session.token}" }
    end

    it 'returns a success status' do
      expect(response).to have_http_status(:ok)
    end

    it 'destroys the session' do
      expect(Session.find_by(token: session.token)).to be_nil
    end
  end

  describe 'GET /api/v1/auth/validate_token' do
    let!(:session) { create(:session, user: user) }
    
    context 'with a valid token' do
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'Authorization' => "Bearer #{session.token}" }
      end

      it 'returns a success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the user data' do
        expect(json_response[:user][:id]).to eq(user.id)
        expect(json_response[:user][:email]).to eq(user.email)
      end
    end

    context 'with an invalid token' do
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'Authorization' => 'Bearer invalid_token' }
      end

      it 'returns an unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/auth/refresh_token' do
    let!(:session) { create(:session, user: user) }
    
    before do
      post '/api/v1/auth/refresh_token', 
           headers: { 'Authorization' => "Bearer #{session.token}" }
    end

    it 'returns a success status' do
      expect(response).to have_http_status(:ok)
    end

    it 'returns a new authentication token' do
      expect(json_response[:auth_token]).to be_present
      expect(json_response[:auth_token]).not_to eq(session.token)
    end
  end

  describe 'POST /api/v1/auth/forgot_password' do
    it 'sends reset password instructions' do
      expect {
        post '/api/v1/auth/forgot_password', 
             params: { email: user.email }
      }.to have_enqueued_job.on_queue('mailers')
      
      expect(response).to be_successful
    end

    it 'handles non-existent email' do
      post '/api/v1/auth/forgot_password', 
           params: { email: 'nonexistent@example.com' }
      
      expect(response).to be_successful
    end
  end

  describe 'POST /api/v1/auth/reset_password' do
    let!(:user_with_token) { create(:user, :with_reset_password_token) }

    context 'with valid token' do
      it 'resets the password' do
        post '/api/v1/auth/reset_password', params: {
          token: user_with_token.reset_password_token,
          new_password: 'new_password123',
          new_password_confirmation: 'new_password123'
        }
        
        expect(response).to be_successful
        expect(user_with_token.reload.authenticate('new_password123')).to be_truthy
      end
    end

    context 'with invalid token' do
      it 'returns an error' do
        post '/api/v1/auth/reset_password', params: {
          token: 'invalid_token',
          new_password: 'new_password123',
          new_password_confirmation: 'new_password123'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to be_present
      end
    end
  end

  describe 'POST /api/v1/auth/change_password' do
    let(:current_password) { 'current_password' }
    let(:new_password) { 'new_password123' }
    let!(:user_with_password) { create(:user, password: current_password) }
    let!(:session) { create(:session, user: user_with_password) }

    before do
      post '/api/v1/auth/change_password', 
           params: {
             current_password: current_password,
             new_password: new_password,
             new_password_confirmation: new_password
           },
           headers: { 'Authorization' => "Bearer #{session.token}" }
    end

    context 'with valid current password' do
      it 'changes the password' do
        expect(response).to be_successful
        expect(user_with_password.reload.authenticate(new_password)).to be_truthy
      end
    end

    context 'with invalid current password' do
      let(:current_password) { 'wrong_password' }
      
      it 'returns an error' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to eq('Contraseña actual incorrecta')
      end
    end
  end

  describe 'POST /api/v1/auth/register' do
    let(:valid_attributes) do
      {
        name: 'New User',
        email: 'newuser@example.com',
        password: 'password123',
        password_confirmation: 'password123'
      }
    end

    context 'with valid attributes' do
      it 'creates a new user' do
        expect {
          post '/api/v1/auth/register', params: { user: valid_attributes }
        }.to change(User, :count).by(1)
        
        expect(response).to have_http_status(:created)
        expect(json_response[:user][:email]).to eq('newuser@example.com')
      end

      it 'sends confirmation email' do
        expect {
          post '/api/v1/auth/register', params: { user: valid_attributes }
        }.to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'with invalid attributes' do
      it 'returns validation errors' do
        post '/api/v1/auth/register', params: { 
          user: valid_attributes.merge(email: 'invalid-email') 
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to be_present
      end
    end
  end

  describe 'GET /api/v1/auth/confirm_email' do
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }
    
    it 'confirms the user email' do
      get '/api/v1/auth/confirm_email', 
          params: { confirmation_token: unconfirmed_user.confirmation_token }
      
      expect(response).to be_successful
      expect(unconfirmed_user.reload).to be_confirmed
    end

    it 'handles invalid token' do
      get '/api/v1/auth/confirm_email', 
          params: { confirmation_token: 'invalid_token' }
      
      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response[:error]).to be_present
    end
  end

  describe 'POST /api/v1/auth/resend_confirmation' do
    let!(:unconfirmed_user) { create(:user, :unconfirmed) }
    
    it 'resends confirmation instructions' do
      expect {
        post '/api/v1/auth/resend_confirmation', 
             params: { email: unconfirmed_user.email }
      }.to have_enqueued_job.on_queue('mailers')
      
      expect(response).to be_successful
    end
  end

  private

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
