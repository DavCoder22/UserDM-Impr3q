# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'API V1 Sessions', type: :request do
  let!(:user) { create(:user, password: 'password123') }
  let(:base_url) { '/api/v1/sessions' }
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

  describe 'POST /api/v1/sessions' do
    context 'with valid credentials' do
      before { post base_url, params: valid_credentials }

      it 'returns a success response' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the user data and authentication token' do
        expect(json_response).to include(
          'user' => a_hash_including(
            'id' => user.id,
            'email' => user.email
          ),
          'token' => be_present
        )
      end
    end

    context 'with invalid credentials' do
      before { post base_url, params: invalid_credentials }

      it 'returns an unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns an error message' do
        expect(json_response).to include('error' => 'Credenciales inválidas')
      end
    end
  end

  describe 'DELETE /api/v1/sessions' do
    let!(:session) { create(:session, user: user) }
    
    before do
      delete "#{base_url}/#{session.token}", 
             headers: { 'Authorization' => "Bearer #{session.token}" }
    end

    it 'returns a success status' do
      expect(response).to have_http_status(:ok)
    end

    it 'destroys the session' do
      expect(Session.find_by(token: session.token)).to be_nil
    end
  end

  describe 'GET /api/v1/sessions/validate' do
    let!(:session) { create(:session, user: user) }
    
    before do
      get "#{base_url}/validate", 
          headers: { 'Authorization' => "Bearer #{session.token}" }
    end

    context 'with a valid token' do
      it 'returns a success status' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the user data' do
        expect(json_response).to include(
          'id' => user.id,
          'email' => user.email
        )
      end
    end

    context 'with an invalid token' do
      before do
        get "#{base_url}/validate", 
            headers: { 'Authorization' => 'Bearer invalid_token' }
      end

      it 'returns an unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
