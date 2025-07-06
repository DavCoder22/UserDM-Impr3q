# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:valid_attributes) do
    {
      name: 'Test User',
      email: 'test@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    }
  end

  let(:invalid_attributes) do
    {
      name: '',
      email: 'invalid-email',
      password: 'short',
      password_confirmation: 'mismatch'
    }
  end

  describe 'GET #index' do
    before do
      create_list(:user, 3)
    end

    context 'as admin' do
      before { api_sign_in(admin) }
      
      it 'returns a success response' do
        get :index
        expect(response).to be_successful
      end

      it 'returns all users' do
        get :index
        expect(json_response[:users].size).to eq(User.count)
      end

      it 'paginates results' do
        get :index, params: { page: 1, per_page: 2 }
        expect(json_response[:meta][:total_pages]).to be > 1
      end
    end

    context 'as regular user' do
      before { api_sign_in(user) }
      
      it 'returns forbidden' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'unauthenticated' do
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'GET #show' do
    let(:target_user) { create(:user) }
    
    context 'as admin' do
      before { api_sign_in(admin) }
      
      it 'returns a success response' do
        get :show, params: { id: target_user.id }
        expect(response).to be_successful
      end

      it 'returns the user' do
        get :show, params: { id: target_user.id }
        expect(json_response[:user][:id]).to eq(target_user.id)
      end
    end

    context 'as the same user' do
      before { api_sign_in(user) }
      
      it 'returns the users own data' do
        get :show, params: { id: user.id }
        expect(response).to be_successful
      end
    end

    context 'as another user' do
      before { api_sign_in(create(:user)) }
      
      it 'returns forbidden' do
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'creates a new User' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it 'renders a JSON response with the new user' do
        post :create, params: { user: valid_attributes }
        expect(response).to have_http_status(:created)
        expect(response.content_type).to include('application/json')
      end

      it 'sends confirmation email' do
        expect {
          post :create, params: { user: valid_attributes }
        }.to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'with invalid params' do
      it 'renders a JSON response with errors' do
        post :create, params: { user: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:errors]).to be_present
      end
    end
  end

  describe 'PUT #update' do
    let(:new_attributes) { { name: 'New Name' } }
    let(:target_user) { create(:user) }

    context 'as admin' do
      before { api_sign_in(admin) }
      
      context 'with valid params' do
        it 'updates the requested user' do
          put :update, params: { id: target_user.id, user: new_attributes }
          target_user.reload
          expect(target_user.name).to eq('New Name')
        end

        it 'renders a JSON response with the user' do
          put :update, params: { id: target_user.id, user: new_attributes }
          expect(response).to be_successful
          expect(json_response[:user][:name]).to eq('New Name')
        end
      end

      context 'with invalid params' do
        it 'renders a JSON response with errors' do
          put :update, params: { id: target_user.id, user: { email: 'invalid' } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(json_response[:errors]).to be_present
        end
      end
    end

    context 'as the same user' do
      before { api_sign_in(user) }
      
      it 'updates their own profile' do
        put :update, params: { id: user.id, user: new_attributes }
        expect(response).to be_successful
      end
    end

    context 'as another user' do
      before { api_sign_in(create(:user)) }
      
      it 'returns forbidden' do
        put :update, params: { id: user.id, user: new_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:user_to_delete) { create(:user) }

    context 'as admin' do
      before { api_sign_in(admin) }
      
      it 'destroys the requested user' do
        expect {
          delete :destroy, params: { id: user_to_delete.id }
        }.to change(User, :count).by(-1)
      end

      it 'returns no content' do
        delete :destroy, params: { id: user_to_delete.id }
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'as the same user' do
      before { api_sign_in(user) }
      
      it 'deletes their own account' do
        expect {
          delete :destroy, params: { id: user.id }
        }.to change(User, :count).by(-1)
      end
    end

    context 'as another user' do
      before { api_sign_in(create(:user)) }
      
      it 'returns forbidden' do
        delete :destroy, params: { id: user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #change_password' do
    let(:current_password) { 'current_password' }
    let(:new_password) { 'new_password123' }
    let!(:user_with_password) { create(:user, password: current_password) }

    before { api_sign_in(user_with_password) }

    context 'with valid current password' do
      it 'changes the password' do
        post :change_password, params: {
          current_password: current_password,
          new_password: new_password,
          new_password_confirmation: new_password
        }
        
        expect(response).to be_successful
        expect(user_with_password.reload.authenticate(new_password)).to be_truthy
      end
    end

    context 'with invalid current password' do
      it 'returns an error' do
        post :change_password, params: {
          current_password: 'wrong_password',
          new_password: new_password,
          new_password_confirmation: new_password
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to eq('Contraseña actual incorrecta')
      end
    end
  end

  describe 'POST #forgot_password' do
    it 'sends reset password instructions' do
      expect {
        post :forgot_password, params: { email: user.email }
      }.to have_enqueued_job.on_queue('mailers')
      
      expect(response).to be_successful
    end

    it 'handles non-existent email' do
      post :forgot_password, params: { email: 'nonexistent@example.com' }
      expect(response).to be_successful
    end
  end

  describe 'POST #reset_password' do
    let!(:user_with_token) { create(:user, :with_reset_password_token) }

    context 'with valid token' do
      it 'resets the password' do
        post :reset_password, params: {
          token: user_with_token.reset_password_token,
          new_password: 'new_password',
          new_password_confirmation: 'new_password'
        }
        
        expect(response).to be_successful
        expect(user_with_token.reload.authenticate('new_password')).to be_truthy
      end
    end

    context 'with invalid token' do
      it 'returns an error' do
        post :reset_password, params: {
          token: 'invalid_token',
          new_password: 'new_password',
          new_password_confirmation: 'new_password'
        }
        
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:error]).to be_present
      end
    end
  end

  describe 'POST #deactivate' do
    let!(:active_user) { create(:user, active: true) }

    context 'as admin' do
      before { api_sign_in(admin) }
      
      it 'deactivates the user' do
        post :deactivate, params: { id: active_user.id }
        expect(response).to be_successful
        expect(active_user.reload).not_to be_active
      end
    end

    context 'as regular user' do
      before { api_sign_in(user) }
      
      it 'returns forbidden' do
        post :deactivate, params: { id: active_user.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST #reactivate' do
    let!(:inactive_user) { create(:user, active: false) }

    context 'as admin' do
      before { api_sign_in(admin) }
      
      it 'reactivates the user' do
        post :reactivate, params: { id: inactive_user.id }
        expect(response).to be_successful
        expect(inactive_user.reload).to be_active
      end
    end
  end

  private

  def api_sign_in(user)
    request.headers['Authorization'] = "Bearer #{user.auth_token}"
  end

  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end
