# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PasswordResetJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:user) { create(:user, :with_reset_password_token) }
  
  it 'encola el trabajo correctamente' do
    expect {
      PasswordResetJob.perform_later(user.id)
    }.to have_enqueued_job(PasswordResetJob)
  end
  
  it 'envía el correo electrónico de restablecimiento' do
    expect {
      perform_enqueued_jobs do
        PasswordResetJob.perform_later(user.id)
      end
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
    
    email = ActionMailer::Base.deliveries.last
    expect(email.to).to include(user.email)
    expect(email.subject).to include('Restablecer contraseña')
  end
  
  it 'maneja usuarios no encontrados' do
    expect {
      PasswordResetJob.perform_now(999999)
    }.not_to raise_error
  end
  
  it 'maneja usuarios sin token de restablecimiento' do
    user.update(reset_password_token: nil)
    
    expect {
      perform_enqueued_jobs do
        PasswordResetJob.perform_later(user.id)
      end
    }.not_to change { ActionMailer::Base.deliveries.size }
  end
  
  it 'programa el trabajo con la prioridad correcta' do
    expect {
      PasswordResetJob.perform_later(user.id)
    }.to have_enqueued_job.on_queue('default')
  end
  
  it 'ejecuta el trabajo correctamente' do
    expect {
      PasswordResetJob.perform_now(user.id)
    }.to change { ActionMailer::Base.deliveries.size }.by(1)
  end
  
  context 'con errores de envío de correo' do
    before do
      allow(UserMailer).to receive(:password_reset).and_raise(Net::SMTPError)
    end
    
    it 'maneja los errores de envío de correo' do
      expect {
        PasswordResetJob.perform_now(user.id)
      }.not_to raise_error
    end
  end
  
  context 'con reintentos configurados' do
    it 'reintenta el trabajo en caso de error' do
      allow_any_instance_of(PasswordResetJob).to receive(:perform).and_raise(StandardError)
      
      assert_performed_jobs 1, only: PasswordResetJob do
        PasswordResetJob.perform_later(user.id)
        rescue StandardError
      end
    end
  end
  
  it 'registra la actividad' do
    expect {
      PasswordResetJob.perform_now(user.id)
    }.to change(ActivityLog, :count).by(1)
    
    log = ActivityLog.last
    expect(log.action).to eq('password_reset_requested')
    expect(log.user).to eq(user)
  end
  
  it 'incluye el token en el correo electrónico' do
    PasswordResetJob.perform_now(user.id)
    email = ActionMailer::Base.deliveries.last
    expect(email.body.encoded).to include(user.reset_password_token)
  end
  
  it 'no envía correo si el usuario está inactivo' do
    user.update(active: false)
    
    expect {
      PasswordResetJob.perform_now(user.id)
    }.not_to change { ActionMailer::Base.deliveries.size }
  end
end
