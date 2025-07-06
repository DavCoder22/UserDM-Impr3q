# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Registrations', type: :request do
  let(:valid_attributes) do
    {
      user: {
        email: 'test@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: 'Test User',
        username: 'testuser'
      }
    }
  end

  let(:invalid_attributes) do
    {
      user: {
        email: 'invalid-email',
        password: '123',
        password_confirmation: '456',
        name: '',
        username: ''
      }
    }
  end

  let(:headers) do
    {
      'Accept' => 'application/json',
      'Content-Type' => 'application/json'
    }
  end

  describe 'POST /api/v1/auth' do
    context 'with valid parameters' do
      it 'creates a new User' do
        expect {
          post '/api/v1/auth', 
               params: valid_attributes.to_json, 
               headers: headers
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['email']).to eq('test@example.com')
        expect(json_response['data']['name']).to eq('Test User')
        expect(json_response['data']['username']).to eq('testuser')
        
        # Verify user is created with correct attributes
        user = User.last
        expect(user.email).to eq('test@example.com')
        expect(user.name).to eq('Test User')
        expect(user.username).to eq('testuser')
        expect(user.confirmed?).to be_falsey
      end

      it 'sends a confirmation email' do
        expect {
          post '/api/v1/auth', 
               params: valid_attributes.to_json, 
               headers: headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include('test@example.com')
        expect(email.subject).to include('Confirmation instructions')
      end

      it 'returns authentication headers' do
        post '/api/v1/auth', 
             params: valid_attributes.to_json, 
             headers: headers

        expect(response.headers['access-token']).to be_present
        expect(response.headers['client']).to be_present
        expect(response.headers['uid']).to eq('test@example.com')
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new User' do
        expect {
          post '/api/v1/auth', 
               params: invalid_attributes.to_json, 
               headers: headers
        }.to change(User, :count).by(0)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['status']).to eq('error')
        expect(json_response['errors']).to include("Email is invalid")
        expect(json_response['errors']).to include("Password is too short")
        expect(json_response['errors']).to include("Name can't be blank")
        expect(json_response['errors']).to include("Username can't be blank")
      end

      it 'does not send confirmation email' do
        expect {
          post '/api/v1/auth', 
               params: invalid_attributes.to_json, 
               headers: headers
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
    end

    context 'with existing email' do
      before { create(:user, email: 'test@example.com') }
      
      it 'returns validation error' do
        post '/api/v1/auth', 
             params: valid_attributes.to_json, 
             headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Email has already been taken')
      end
    end

    context 'with missing user root key' do
      it 'returns parameter missing error' do
        post '/api/v1/auth', 
             params: {}.to_json, 
             headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to eq('param is missing or the value is empty: user')
      end
    end
  end

  describe 'PUT /api/v1/auth' do
    let(:user) { create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    
    context 'with valid parameters' do
      let(:update_attributes) do
        {
          user: {
            name: 'Updated Name',
            current_password: 'password123'
          }
        }
      end

      it 'updates the user' do
        put '/api/v1/auth', 
            params: update_attributes.to_json, 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['data']['name']).to eq('Updated Name')
        
        user.reload
        expect(user.name).to eq('Updated Name')
      end

      it 'allows email update with current password' do
        update_attributes[:user][:email] = 'newemail@example.com'
        
        put '/api/v1/auth', 
            params: update_attributes.to_json, 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['email']).to eq('newemail@example.com')
        
        user.reload
        expect(user.email).to eq('newemail@example.com')
        expect(user.unconfirmed_email).to be_nil
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        put '/api/v1/auth', 
            params: { user: { email: 'invalid-email' } }.to_json, 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Email is invalid')
      end

      it 'requires current_password for password changes' do
        put '/api/v1/auth', 
            params: { user: { password: 'newpassword123' } }.to_json, 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Current password can\'t be blank')
      end

      it 'validates current_password' do
        put '/api/v1/auth', 
            params: { 
              user: { 
                password: 'newpassword123',
                current_password: 'wrongpassword' 
              } 
            }.to_json, 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Current password is invalid')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        put '/api/v1/auth', 
            params: { user: { name: 'New Name' } }.to_json, 
            headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors']).to include('You need to sign in or sign up before continuing.')
      end
    end
  end

  describe 'DELETE /api/v1/auth' do
    let!(:user) { create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    
    context 'with valid authentication' do
      it 'deletes the user account' do
        expect {
          delete '/api/v1/auth', 
                 headers: auth_headers.merge(headers)
        }.to change(User, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('success')
        expect(json_response['message']).to eq('Account with UID ":email" has been destroyed')
      end

      it 'sends goodbye email' do
        expect {
          delete '/api/v1/auth', 
                 headers: auth_headers.merge(headers)
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(user.email)
        expect(email.subject).to include('Your account has been deleted')
      end
    end

    context 'without authentication' do
      it 'returns unauthorized error' do
        delete '/api/v1/auth', 
               headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors']).to include('You need to sign in or sign up before continuing.')
      end
    end
  end

  describe 'POST /api/v1/auth/password' do
    let!(:user) { create(:user) }
    
    context 'with valid email' do
      it 'sends password reset instructions' do
        expect {
          post '/api/v1/auth/password', 
               params: { email: user.email, redirect_url: 'http://example.com/reset' }.to_json, 
               headers: headers
        }.to change { ActionMailer::Base.deliveries.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to eq('You will receive an email with instructions on how to reset your password in a few minutes.')
        
        email = ActionMailer::Base.deliveries.last
        expect(email.to).to include(user.email)
        expect(email.subject).to include('Reset password instructions')
      end
    end

    context 'with non-existent email' do
      it 'returns success for security reasons' do
        post '/api/v1/auth/password', 
             params: { email: 'nonexistent@example.com' }.to_json, 
             headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to include('If your email address exists in our database')
      end
    end
  end

  describe 'PUT /api/v1/auth/password' do
    let!(:user) { create(:user) }
    let(:reset_password_token) { user.send_reset_password_instructions }
    
    context 'with valid parameters' do
      it 'updates the password' do
        put '/api/v1/auth/password', 
            params: { 
              password: 'newpassword123',
              password_confirmation: 'newpassword123',
              reset_password_token: reset_password_token
            }.to_json, 
            headers: headers

        expect(response).to have_http_status(:ok)
        expect(json_response['message']).to include('Your password has been changed successfully.')
        
        # Verify the password was actually changed
        user.reload
        expect(user.valid_password?('newpassword123')).to be_truthy
      end
    end

    context 'with invalid token' do
      it 'returns an error' do
        put '/api/v1/auth/password', 
            params: { 
              password: 'newpassword123',
              password_confirmation: 'newpassword123',
              reset_password_token: 'invalid_token'
            }.to_json, 
            headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('Reset password token is invalid')
      end
    end

    context 'with password confirmation mismatch' do
      it 'returns validation error' do
        put '/api/v1/auth/password', 
            params: { 
              password: 'newpassword123',
              password_confirmation: 'mismatch',
              reset_password_token: reset_password_token
            }.to_json, 
            headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include("Password confirmation doesn't match")
      end
    end
  end

  describe 'GET /api/v1/auth/validate_token' do
    let!(:user) { create(:user) }
    let(:auth_headers) { user.create_new_auth_token }
    
    context 'with valid token' do
      it 'returns the user data' do
        get '/api/v1/auth/validate_token', 
            headers: auth_headers.merge(headers)

        expect(response).to have_http_status(:ok)
        expect(json_response['data']['id']).to eq(user.id)
        expect(json_response['data']['email']).to eq(user.email)
      end
    end

    context 'with invalid token' do
      it 'returns unauthorized error' do
        get '/api/v1/auth/validate_token', 
            headers: { 'access-token' => 'invalid', 'uid' => user.email, 'client' => 'client' }.merge(headers)

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['errors']).to include('Invalid login credentials')
      end
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
