# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserService do
  let(:service) { described_class.new }
  let(:admin) { create(:user, :admin) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:valid_attributes) do
    {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'password123',
      password_confirmation: 'password123'
    }
  end

  describe '#create_user' do
    context 'with valid attributes' do
      it 'creates a new user' do
        expect {
          service.create_user(valid_attributes)
        }.to change(User, :count).by(1)
      end

      it 'returns the created user' do
        result = service.create_user(valid_attributes)
        expect(result[:user]).to be_persisted
        expect(result[:user].email).to eq('john@example.com')
      end

      it 'sends confirmation instructions' do
        expect {
          service.create_user(valid_attributes)
        }.to have_enqueued_job.on_queue('mailers')
      end
    end

    context 'with invalid attributes' do
      it 'does not create a user' do
        expect {
          service.create_user(valid_attributes.merge(email: ''))
        }.not_to change(User, :count)
      end

      it 'returns errors' do
        result = service.create_user(valid_attributes.merge(email: ''))
        expect(result[:errors]).to include("Email can't be blank")
      end
    end
  end

  describe '#update_user' do
    let(:update_attributes) { { name: 'Updated Name' } }

    context 'when updating own profile' do
      it 'updates the user' do
        result = service.update_user(user, user, update_attributes)
        expect(result[:success]).to be_truthy
        expect(user.reload.name).to eq('Updated Name')
      end
    end

    context 'when admin updates another user' do
      it 'updates the user' do
        result = service.update_user(admin, user, update_attributes)
        expect(result[:success]).to be_truthy
        expect(user.reload.name).to eq('Updated Name')
      end
    end

    context 'when non-admin updates another user' do
      it 'returns unauthorized error' do
        result = service.update_user(other_user, user, update_attributes)
        expect(result[:error]).to eq('No autorizado')
        expect(user.reload.name).not_to eq('Updated Name')
      end
    end

    context 'with invalid attributes' do
      it 'returns errors' do
        result = service.update_user(user, user, { email: 'invalid' })
        expect(result[:errors]).to include('Email no es válido')
      end
    end
  end

  describe '#delete_user' do
    let!(:user_to_delete) { create(:user) }

    context 'when admin deletes a user' do
      it 'deletes the user' do
        expect {
          service.delete_user(admin, user_to_delete)
        }.to change(User, :count).by(-1)
      end

      it 'returns success' do
        result = service.delete_user(admin, user_to_delete)
        expect(result[:success]).to be_truthy
      end
    end

    context 'when user deletes their own account' do
      it 'deletes the user' do
        expect {
          service.delete_user(user_to_delete, user_to_delete)
        }.to change(User, :count).by(-1)
      end
    end

    context 'when non-admin tries to delete another user' do
      it 'does not delete the user' do
        expect {
          service.delete_user(other_user, user_to_delete)
        }.not_to change(User, :count)
      end

      it 'returns unauthorized error' do
        result = service.delete_user(other_user, user_to_delete)
        expect(result[:error]).to eq('No autorizado')
      end
    end
  end

  describe '#change_password' do
    let(:current_password) { 'current_password' }
    let(:new_password) { 'new_password123' }
    let!(:user_with_password) { create(:user, password: current_password) }

    context 'with valid current password' do
      it 'changes the password' do
        result = service.change_password(
          user_with_password,
          current_password,
          new_password,
          new_password
        )
        
        expect(result[:success]).to be_truthy
        expect(user_with_password.reload.authenticate(new_password)).to be_truthy
      end
    end

    context 'with invalid current password' do
      it 'returns an error' do
        result = service.change_password(
          user_with_password,
          'wrong_password',
          new_password,
          new_password
        )
        
        expect(result[:error]).to eq('Contraseña actual incorrecta')
      end
    end

    context 'when new passwords do not match' do
      it 'returns an error' do
        result = service.change_password(
          user_with_password,
          current_password,
          new_password,
          'different_password'
        )
        
        expect(result[:error]).to eq('Las contraseñas no coinciden')
      end
    end
  end

  describe '#request_password_reset' do
    it 'generates a reset token' do
      expect {
        service.request_password_reset(user.email)
      }.to change { user.reload.reset_password_token }.from(nil)
    end

    it 'sends reset instructions' do
      expect {
        service.request_password_reset(user.email)
      }.to have_enqueued_job.on_queue('mailers')
    end

    it 'handles non-existent email' do
      expect {
        service.request_password_reset('nonexistent@example.com')
      }.not_to raise_error
    end
  end

  describe '#reset_password' do
    let!(:user_with_token) { create(:user, :with_reset_password_token) }

    context 'with valid token' do
      it 'resets the password' do
        result = service.reset_password(
          user_with_token.reset_password_token,
          'new_password',
          'new_password'
        )
        
        expect(result[:success]).to be_truthy
        expect(user_with_token.reload.authenticate('new_password')).to be_truthy
        expect(user_with_token.reset_password_token).to be_nil
      end
    end

    context 'with invalid token' do
      it 'returns an error' do
        result = service.reset_password(
          'invalid_token',
          'new_password',
          'new_password'
        )
        
        expect(result[:error]).to eq('Token inválido o expirado')
      end
    end
  end

  describe '#deactivate_user' do
    let!(:active_user) { create(:user, active: true) }

    context 'when admin deactivates a user' do
      it 'deactivates the user' do
        result = service.deactivate_user(admin, active_user)
        expect(result[:success]).to be_truthy
        expect(active_user.reload).not_to be_active
      end
    end

    context 'when non-admin tries to deactivate a user' do
      it 'returns unauthorized error' do
        result = service.deactivate_user(other_user, active_user)
        expect(result[:error]).to eq('No autorizado')
        expect(active_user.reload).to be_active
      end
    end
  end

  describe '#reactivate_user' do
    let!(:inactive_user) { create(:user, active: false) }

    context 'when admin reactivates a user' do
      it 'reactivates the user' do
        result = service.reactivate_user(admin, inactive_user)
        expect(result[:success]).to be_truthy
        expect(inactive_user.reload).to be_active
      end
    end
  end

  describe '#list_users' do
    before do
      5.times { create(:user) }
    end

    it 'returns all users for admin' do
      result = service.list_users(admin, {})
      expect(result[:users].count).to eq(User.count)
    end

    it 'filters by active status' do
      create(:user, active: false)
      result = service.list_users(admin, { active: 'true' })
      expect(result[:users].count).to eq(User.active.count)
    end

    it 'paginates results' do
      result = service.list_users(admin, { page: 1, per_page: 2 })
      expect(result[:users].count).to eq(2)
      expect(result[:meta][:total_pages]).to be > 1
    end
  end
end
