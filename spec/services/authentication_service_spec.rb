# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthenticationService do
  let(:user) { create(:user, password: 'password') }
  let(:service) { described_class.new }
  
  describe '#authenticate' do
    context 'con credenciales válidas' do
      it 'devuelve el usuario y el token' do
        result = service.authenticate(user.email, 'password')
        expect(result[:user]).to eq(user)
        expect(result[:token]).to be_present
      end
    end
    
    context 'con contraseña incorrecta' do
      it 'devuelve un error' do
        result = service.authenticate(user.email, 'wrong_password')
        expect(result[:error]).to eq('Credenciales inválidas')
      end
    end
    
    context 'con usuario inactivo' do
      let!(:inactive_user) { create(:user, :inactive, password: 'password') }
      
      it 'devuelve un error' do
        result = service.authenticate(inactive_user.email, 'password')
        expect(result[:error]).to eq('Cuenta inactiva')
      end
    end
    
    context 'con email no encontrado' do
      it 'devuelve un error' do
        result = service.authenticate('nonexistent@example.com', 'password')
        expect(result[:error]).to eq('Credenciales inválidas')
      end
    end
  end
  
  describe '#validate_token' do
    let!(:session) { create(:session, user: user) }
    
    context 'con token válido' do
      it 'devuelve el usuario y la sesión' do
        result = service.validate_token(session.token)
        expect(result[:user]).to eq(user)
        expect(result[:session]).to eq(session)
      end
    end
    
    context 'con token inválido' do
      it 'devuelve un error' do
        result = service.validate_token('invalid_token')
        expect(result[:error]).to eq('Token inválido o expirado')
      end
    end
    
    context 'con sesión expirada' do
      let!(:expired_session) { create(:session, user: user, expires_at: 1.day.ago) }
      
      it 'devuelve un error' do
        result = service.validate_token(expired_session.token)
        expect(result[:error]).to eq('Sesión expirada')
      end
    end
  end
  
  describe '#logout' do
    let!(:session) { create(:session, user: user) }
    
    it 'invalida la sesión' do
      expect {
        service.logout(session.token)
      }.to change { Session.active.count }.by(-1)
    end
  end
  
  describe '#request_password_reset' do
    it 'genera un token de restablecimiento' do
      expect {
        service.request_password_reset(user.email)
      }.to change { user.reload.reset_password_token }.from(nil)
    end
    
    it 'envía un correo electrónico' do
      expect {
        service.request_password_reset(user.email)
      }.to have_enqueued_job.on_queue('mailers')
    end
    
    context 'con email no encontrado' do
      it 'no genera un token' do
        expect {
          service.request_password_reset('nonexistent@example.com')
        }.not_to change { user.reload.reset_password_token }
      end
    end
  end
  
  describe '#reset_password' do
    let!(:user_with_token) { create(:user, :with_reset_password_token) }
    
    it 'restablece la contraseña' do
      result = service.reset_password(
        user_with_token.reset_password_token,
        'new_password',
        'new_password'
      )
      
      expect(result[:success]).to be_truthy
      expect(user_with_token.reload.authenticate('new_password')).to be_truthy
      expect(user_with_token.reset_password_token).to be_nil
    end
    
    context 'con token inválido' do
      it 'devuelve un error' do
        result = service.reset_password(
          'invalid_token',
          'new_password',
          'new_password'
        )
        
        expect(result[:error]).to eq('Token inválido o expirado')
      end
    end
    
    context 'con contraseñas que no coinciden' do
      it 'devuelve un error' do
        result = service.reset_password(
          user_with_token.reset_password_token,
          'new_password',
          'different_password'
        )
        
        expect(result[:error]).to eq('Las contraseñas no coinciden')
      end
    end
  end
  
  describe '#change_password' do
    it 'cambia la contraseña con la actual correcta' do
      result = service.change_password(
        user,
        'password',
        'new_password',
        'new_password'
      )
      
      expect(result[:success]).to be_truthy
      expect(user.reload.authenticate('new_password')).to be_truthy
    end
    
    it 'devuelve un error con la contraseña actual incorrecta' do
      result = service.change_password(
        user,
        'wrong_password',
        'new_password',
        'new_password'
      )
      
      expect(result[:error]).to eq('Contraseña actual incorrecta')
    end
  end
end
