# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth Authentication', type: :request do
  include_context 'OmniAuth testing helpers'
  
  let(:provider) { :github } # Default provider for testing
  let(:auth_hash) do
    OmniAuth::AuthHash.new({
      provider: provider.to_s,
      uid: '12345',
      info: {
        email: 'oauth@example.com',
        name: 'OAuth User',
        image: 'http://example.com/image.jpg'
      },
      credentials: {
        token: 'mock_token',
        refresh_token: 'mock_refresh_token',
        expires_at: Time.zone.now + 1.week.to_i
      }
    })
  end
  
  before do
    # Reset the test mode and clear mocks
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[provider] = nil
    
    # Stub the OmniAuth configuration for the test environment
    Rails.application.env_config['omniauth.auth'] = auth_hash
    
    # Clear any existing authentication
    sign_out :user
  end
  
  describe 'OAuth Authentication Flow' do
    context 'with valid credentials' do
      it 'creates a new user account' do
        expect {
          get "/auth/#{provider}/callback"
          follow_redirect!
        }.to change(User, :count).by(1)
        
        user = User.last
        expect(user.email).to eq('oauth@example.com')
        expect(user.name).to eq('OAuth User')
        expect(user.provider).to eq(provider.to_s)
        expect(user.uid).to eq('12345')
        
        # Should be signed in
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq('Successfully authenticated from GitHub account.')
      end
      
      it 'handles existing user authentication' do
        # Create a user with the same email
        user = create(:user, email: 'oauth@example.com')
        
        expect {
          get "/auth/#{provider}/callback"
          follow_redirect!
        }.not_to change(User, :count)
        
        # Should sign in the existing user
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(root_path)
      end
      
      it 'links OAuth account to existing authenticated user' do
        # Sign in first
        user = create(:user, email: 'existing@example.com')
        sign_in user
        
        expect {
          get "/auth/#{provider}/callback"
          follow_redirect!
        }.not_to change(User, :count)
        
        # Should link the OAuth account
        user.reload
        expect(user.provider).to eq(provider.to_s)
        expect(user.uid).to eq('12345')
        expect(response).to redirect_to(edit_user_registration_path)
        expect(flash[:notice]).to eq('Successfully linked GitHub account.')
      end
    end
    
    context 'with invalid credentials' do
      before do
        OmniAuth.config.mock_auth[provider] = :invalid_credentials
      end
      
      it 'handles authentication failure' do
        get "/auth/#{provider}/callback"
        
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to include('Could not authenticate you from GitHub')
        expect(controller.current_user).to be_nil
      end
    end
    
    context 'with missing email' do
      let(:auth_hash) do
        OmniAuth::AuthHash.new({
          provider: provider.to_s,
          uid: '12345',
          info: {
            name: 'No Email User',
            email: nil
          },
          credentials: {
            token: 'mock_token'
          }
        })
      end
      
      it 'redirects to email collection page' do
        get "/auth/#{provider}/callback"
        
        expect(response).to redirect_to(users_auth_email_path)
        expect(session['devise.oauth_data']).to be_present
        expect(controller.current_user).to be_nil
      end
    end
    
    context 'with existing provider/uid combination' do
      before do
        create(:user, provider: provider.to_s, uid: '12345', email: 'existing@example.com')
      end
      
      it 'signs in the existing user' do
        expect {
          get "/auth/#{provider}/callback"
          follow_redirect!
        }.not_to change(User, :count)
        
        user = User.find_by(provider: provider.to_s, uid: '12345')
        expect(controller.current_user).to eq(user)
        expect(response).to redirect_to(root_path)
      end
    end
  end
  
  describe 'OAuth Email Collection' do
    before do
      auth_hash.info.email = nil
      OmniAuth.config.mock_auth[provider] = auth_hash
      
      # Simulate the OAuth callback that would set the session
      get "/auth/#{provider}/callback"
    end
    
    it 'shows the email collection form' do
      get users_auth_email_path
      
      expect(response).to be_successful
      expect(response.body).to include('Please provide your email')
    end
    
    it 'creates a user with the provided email' do
      expect {
        post users_auth_email_path, params: {
          user: { email: 'new@example.com' }
        }
        follow_redirect!
      }.to change(User, :count).by(1)
      
      user = User.last
      expect(user.email).to eq('new@example.com')
      expect(user.provider).to eq(provider.to_s)
      expect(user.uid).to eq('12345')
      expect(response).to redirect_to(root_path)
    end
    
    it 'validates email format' do
      post users_auth_email_path, params: {
        user: { email: 'invalid-email' }
      }
      
      expect(response).to be_successful
      expect(response.body).to include('Email is invalid')
    end
    
    it 'handles duplicate emails' do
      create(:user, email: 'existing@example.com')
      
      post users_auth_email_path, params: {
        user: { email: 'existing@example.com' }
      }
      
      expect(response).to be_successful
      expect(response.body).to include('Email has already been taken')
    end
  end
  
  describe 'OAuth Account Management' do
    let(:user) { create(:user) }
    
    before do
      sign_in user
    end
    
    it 'shows linked accounts' do
      user.identities.create(provider: 'github', uid: '12345')
      
      get oauth_connections_path
      
      expect(response).to be_successful
      expect(response.body).to include('GitHub')
    end
    
    it 'allows unlinking an account' do
      identity = user.identities.create(provider: 'github', uid: '12345')
      
      expect {
        delete oauth_connection_path(identity)
      }.to change(user.identities, :count).by(-1)
      
      expect(response).to redirect_to(oauth_connections_path)
      expect(flash[:notice]).to include('Successfully unlinked GitHub account')
    end
    
    it 'prevents unlinking the last authentication method' do
      identity = user.identities.create(provider: 'github', uid: '12345')
      user.update(encrypted_password: nil) # No password set
      
      expect {
        delete oauth_connection_path(identity)
      }.not_to change(user.identities, :count)
      
      expect(response).to redirect_to(oauth_connections_path)
      expect(flash[:alert]).to include('Cannot unlink the last authentication method')
    end
  end
  
  describe 'Provider-Specific Flows' do
    %i[github google_oauth2 facebook twitter linkedin microsoft_office365].each do |provider|
      context "with #{provider} provider" do
        let(:provider) { provider }
        
        it "handles authentication with #{provider}" do
          OmniAuth.config.mock_auth[provider] = auth_hash
          
          expect {
            get "/auth/#{provider}/callback"
            follow_redirect!
          }.to change(User, :count).by(1)
          
          user = User.last
          expect(user.provider).to eq(provider.to_s)
          expect(user.uid).to eq('12345')
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
  
  describe 'Error Handling' do
    it 'handles CSRF attacks' do
      # Simulate CSRF by clearing the session before the callback
      get "/auth/#{provider}"
      reset_session
      
      expect {
        get "/auth/#{provider}/callback"
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end
    
    it 'handles OAuth service errors' do
      OmniAuth.config.mock_auth[provider] = :service_unavailable
      
      get "/auth/#{provider}/callback"
      
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Service temporarily unavailable')
    end
    
    it 'handles timeouts' do
      allow_any_instance_of(OmniAuth::Strategy).to receive(:callback_phase).and_raise(Timeout::Error)
      
      get "/auth/#{provider}/callback"
      
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('Request timed out')
    end
  end
  
  describe 'OAuth Scopes and Permissions' do
    let(:scoped_auth_hash) do
      auth_hash.tap do |h|
        h.info = h.info.merge(email: 'scoped@example.com')
        h.extra = {
          raw_info: {
            # Example GitHub scopes
            scopes: ['user:email', 'read:user']
          }
        }
      end
    end
    
    before do
      OmniAuth.config.mock_auth[provider] = scoped_auth_hash
    end
    
    it 'stores granted scopes' do
      get "/auth/#{provider}/callback"
      
      identity = Identity.last
      expect(identity.scope).to include('user:email')
      expect(identity.scope).to include('read:user')
    end
    
    it 'handles insufficient permissions' do
      scoped_auth_hash.extra[:raw_info][:scopes] = ['public_repo'] # Missing required scopes
      
      get "/auth/#{provider}/callback"
      
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to include('insufficient permissions')
    end
  end
  
  describe 'OAuth Token Management' do
    let(:user) { create(:user) }
    let(:identity) { user.identities.create(provider: provider.to_s, uid: '12345', token: 'old_token') }
    
    before do
      sign_in user
      OmniAuth.config.mock_auth[provider] = auth_hash
    end
    
    it 'refreshes expired tokens' do
      # Simulate an expired token
      identity.update(token: 'expired_token', expires_at: 1.hour.ago)
      
      # Stub the token refresh
      allow_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_return(
        double(token: 'new_token', expires_at: 1.week.from_now.to_i)
      )
      
      get "/auth/#{provider}/refresh_token"
      
      identity.reload
      expect(identity.token).to eq('new_token')
      expect(response).to redirect_to(oauth_connections_path)
    end
    
    it 'handles refresh failures' do
      identity.update(token: 'expired_token', refresh_token: 'refresh_token')
      
      # Simulate refresh failure
      allow_any_instance_of(OAuth2::AccessToken).to receive(:refresh!).and_raise(OAuth2::Error, 'invalid_grant')
      
      get "/auth/#{provider}/refresh_token"
      
      expect(response).to redirect_to(oauth_connections_path)
      expect(flash[:alert]).to include('Failed to refresh token')
    end
  end
end
