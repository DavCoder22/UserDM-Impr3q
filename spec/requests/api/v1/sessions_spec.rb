# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Sessions', type: :request do
  let!(:user) { create(:user, password: 'password123') }
  let(:valid_credentials) do
    {
      email: user.email,
      password: 'password123'
    }
  end
  
  let(:invalid_credentials) do
    {
      email: 'invalid@example.com',
      password: 'wrongpassword'
    }
  end
  
  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  describe 'POST /api/v1/auth/sign_in' do
    context 'with valid credentials' do
      before do
        post '/api/v1/auth/sign_in', 
             params: valid_credentials.to_json, 
             headers: headers
      end
      
      it 'returns status code 200' do
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns the user data' do
        expect(json_response['data']['email']).to eq(user.email)
        expect(json_response['data']['name']).to eq(user.name)
      end
      
      it 'returns authentication headers' do
        expect(response.headers['access-token']).to be_present
        expect(response.headers['client']).to be_present
        expect(response.headers['uid']).to eq(user.email)
        expect(response.headers['expiry']).to be_present
      end
      
      it 'sets the token in the response' do
        expect(json_response['token']).to be_present
      end
      
      it 'increments the sign_in_count' do
        expect { 
          post '/api/v1/auth/sign_in', 
               params: valid_credentials.to_json, 
               headers: headers 
        }.to change { user.reload.sign_in_count }.by(1)
      end
      
      it 'updates the last_sign_in_at timestamp' do
        expect { 
          post '/api/v1/auth/sign_in', 
               params: valid_credentials.to_json, 
               headers: headers 
          user.reload
        }.to change(user, :last_sign_in_at)
      end
    end
    
    context 'with invalid credentials' do
      before do
        post '/api/v1/auth/sign_in', 
             params: invalid_credentials.to_json, 
             headers: headers
      end
      
      it 'returns status code 401' do
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns an error message' do
        expect(json_response['errors']).to include('Invalid login credentials. Please try again.')
      end
      
      it 'does not return authentication headers' do
        expect(response.headers['access-token']).to be_nil
        expect(response.headers['client']).to be_nil
        expect(response.headers['uid']).to be_nil
      end
      
      it 'increments the failed_attempts counter' do
        expect { 
          post '/api/v1/auth/sign_in', 
               params: invalid_credentials.to_json, 
               headers: headers 
        }.to change { user.reload.failed_attempts }.by(1)
      end
      
      context 'when account is locked' do
        before do
          user.update(failed_attempts: User.maximum_attempts)
          post '/api/v1/auth/sign_in', 
               params: { email: user.email, password: 'wrongpassword' }.to_json, 
               headers: headers
        end
        
        it 'returns status code 401' do
          expect(response).to have_http_status(:unauthorized)
        end
        
        it 'returns an account locked message' do
          expect(json_response['errors']).to include('Your account is locked.')
        end
        
        it 'locks the account' do
          expect(user.reload.access_locked?).to be_truthy
        end
      end
    end
    
    context 'with unconfirmed email' do
      let!(:unconfirmed_user) { create(:user, :unconfirmed, password: 'password123') }
      
      before do
        post '/api/v1/auth/sign_in', 
             params: { email: unconfirmed_user.email, password: 'password123' }.to_json, 
             headers: headers
      end
      
      it 'returns status code 401' do
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns an unconfirmed message' do
        expect(json_response['errors']).to include('You have to confirm your email address before continuing.')
      end
    end
    
    context 'with missing parameters' do
      it 'returns status code 422 when email is missing' do
        post '/api/v1/auth/sign_in', 
             params: { password: 'password123' }.to_json, 
             headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('email is missing')
      end
      
      it 'returns status code 422 when password is missing' do
        post '/api/v1/auth/sign_in', 
             params: { email: user.email }.to_json, 
             headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('password is missing')
      end
    end
    
    context 'with remember me option' do
      it 'sets a remember token when remember_me is true' do
        post '/api/v1/auth/sign_in', 
             params: valid_credentials.merge(remember_me: true).to_json, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(response.cookies['remember_user_token']).to be_present
      end
      
      it 'does not set a remember token when remember_me is false' do
        post '/api/v1/auth/sign_in', 
             params: valid_credentials.merge(remember_me: false).to_json, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(response.cookies['remember_user_token']).to be_nil
      end
    end
  end
  
  describe 'DELETE /api/v1/auth/sign_out' do
    let(:auth_headers) { user.create_new_auth_token }
    
    before do
      delete '/api/v1/auth/sign_out', 
             headers: auth_headers.merge(headers)
    end
    
    it 'returns status code 200' do
      expect(response).to have_http_status(:ok)
    end
    
    it 'returns a success message' do
      expect(json_response['message']).to eq('Signed out successfully.')
    end
    
    it 'invalidates the token' do
      get '/api/v1/auth/validate_token', 
          headers: auth_headers.merge(headers)
      
      expect(response).to have_http_status(:unauthorized)
    end
    
    it 'clears the auth headers' do
      expect(response.headers['access-token']).to be_nil
      expect(response.headers['client']).to be_nil
      expect(response.headers['uid']).to be_nil
    end
    
    context 'with invalid token' do
      it 'returns status code 404' do
        delete '/api/v1/auth/sign_out', 
               headers: { 'access-token' => 'invalid', 'client' => 'invalid', 'uid' => 'invalid@example.com' }.merge(headers)
        
        expect(response).to have_http_status(:not_found)
        expect(json_response['errors']).to include('User was not found or was not logged in.')
      end
    end
  end
  
  describe 'GET /api/v1/auth/validate_token' do
    let(:auth_headers) { user.create_new_auth_token }
    
    before do
      get '/api/v1/auth/validate_token', 
          headers: auth_headers.merge(headers)
    end
    
    it 'returns status code 200' do
      expect(response).to have_http_status(:ok)
    end
    
    it 'returns the user data' do
      expect(json_response['data']['email']).to eq(user.email)
      expect(json_response['data']['name']).to eq(user.name)
    end
    
    it 'returns new auth headers' do
      expect(response.headers['access-token']).to be_present
      expect(response.headers['client']).to be_present
      expect(response.headers['uid']).to eq(user.email)
    end
    
    context 'with expired token' do
      before do
        travel_to 2.days.from_now do
          get '/api/v1/auth/validate_token', 
              headers: auth_headers.merge(headers)
        end
      end
      
      it 'returns status code 401' do
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns an expired token message' do
        expect(json_response['errors']).to include('Your session has expired. Please log in again.')
      end
    end
    
    context 'with invalid token' do
      before do
        get '/api/v1/auth/validate_token', 
            headers: { 'access-token' => 'invalid', 'client' => 'invalid', 'uid' => user.email }.merge(headers)
      end
      
      it 'returns status code 401' do
        expect(response).to have_http_status(:unauthorized)
      end
      
      it 'returns an invalid token message' do
        expect(json_response['errors']).to include('Invalid token.')
      end
    end
  end
  
  describe 'POST /api/v1/auth/password' do
    let(:valid_email) { { email: user.email } }
    let(:invalid_email) { { email: 'nonexistent@example.com' } }
    
    context 'with valid email' do
      it 'sends password reset instructions' do
        expect {
          post '/api/v1/auth/password', 
               params: valid_email.to_json, 
               headers: headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('You will receive an email with instructions on how to reset your password in a few minutes.')
      end
    end
    
    context 'with invalid email' do
      it 'returns success for security reasons' do
        post '/api/v1/auth/password', 
             params: invalid_email.to_json, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to include('If your email address exists in our database')
      end
    end
    
    context 'with missing email' do
      it 'returns unprocessable entity' do
        post '/api/v1/auth/password', 
             params: {}.to_json, 
             headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('email is missing')
      end
    end
  end
  
  describe 'PUT /api/v1/auth/password' do
    let(:reset_password_token) { user.send_reset_password_instructions }
    let(:valid_params) do
      {
        password: 'newpassword123',
        password_confirmation: 'newpassword123',
        reset_password_token: reset_password_token
      }
    end
    
    context 'with valid parameters' do
      before do
        put '/api/v1/auth/password', 
            params: valid_params.to_json, 
            headers: headers
      end
      
      it 'returns status code 200' do
        expect(response).to have_http_status(:ok)
      end
      
      it 'returns a success message' do
        expect(json_response['message']).to include('Your password has been changed successfully.')
      end
      
      it 'updates the password' do
        user.reload
        expect(user.valid_password?('newpassword123')).to be_truthy
      end
      
      it 'sends a password changed notification' do
        expect(ActionMailer::Base.deliveries.last.subject).to include('Your password has been changed')
      end
    end
    
    context 'with invalid token' do
      it 'returns unprocessable entity' do
        put '/api/v1/auth/password', 
            params: valid_params.merge(reset_password_token: 'invalid').to_json, 
            headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Reset password token is invalid')
      end
    end
    
    context 'with password confirmation mismatch' do
      it 'returns unprocessable entity' do
        put '/api/v1/auth/password', 
            params: valid_params.merge(password_confirmation: 'mismatch').to_json, 
            headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Password confirmation doesn't match")
      end
    end
    
    context 'with missing parameters' do
      it 'returns unprocessable entity when password is missing' do
        put '/api/v1/auth/password', 
            params: valid_params.except(:password).to_json, 
            headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('password is missing')
      end
      
      it 'returns unprocessable entity when token is missing' do
        put '/api/v1/auth/password', 
            params: valid_params.except(:reset_password_token).to_json, 
            headers: headers
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('reset_password_token is missing')
      end
    end
  end
  
  private
  
  def json_response
    JSON.parse(response.body)
  end
end
