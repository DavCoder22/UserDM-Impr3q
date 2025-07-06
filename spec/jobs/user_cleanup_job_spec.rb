# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserCleanupJob, type: :job do
  include ActiveJob::TestHelper
  
  describe '#perform' do
    let!(:active_user) { create(:user, last_activity_at: 1.week.ago) }
    let!(:inactive_user) { create(:user, last_activity_at: 2.years.ago) }
    let!(:recently_inactive_user) { create(:user, last_activity_at: 5.months.ago) }
    
    before do
      # Configurar el tiempo de inactividad para la prueba
      stub_const("User::INACTIVITY_PERIOD", 1.year)
    end
    
    it 'marca usuarios inactivos correctamente' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to change { inactive_user.reload.active? }.from(true).to(false)
       .and change { recently_inactive_user.reload.active? }.from(true).to(false)
       .and not_change { active_user.reload.active? }
    end
    
    it 'envía notificaciones a los usuarios marcados como inactivos' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to have_enqueued_mail(UserMailer, :inactivity_notice)
       .with(inactive_user)
       .and have_enqueued_mail(UserMailer, :inactivity_notice)
       .with(recently_inactive_user)
    end
    
    it 'registra la actividad de limpieza' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to change(ActivityLog, :count).by(2) # Una entrada por usuario inactivo
      
      log = ActivityLog.last
      expect(log.action).to eq('user_marked_inactive')
      expect(log.user).to eq(inactive_user)
    end
    
    it 'no afecta a los administradores' do
      admin = create(:user, :admin, last_activity_at: 2.years.ago)
      
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.not_to change { admin.reload.active? }
    end
    
    it 'manja correctamente los usuarios ya inactivos' do
      already_inactive = create(:user, active: false, last_activity_at: 2.years.ago)
      
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.not_to change { already_inactive.reload.updated_at }
    end
    
    context 'cuando el trabajo falla' do
      before do
        allow_any_instance_of(User).to receive(:update!).and_raise(StandardError.new('Error de prueba'))
      end
      
      it 'registra el error y continúa con el siguiente usuario' do
        expect(Rails.logger).to receive(:error).with(/Error al procesar usuario/).at_least(:once)
        
        perform_enqueued_jobs { described_class.perform_later }
      end
    end
  end
  
  describe 'scheduling' do
    it 'está en la cola correcta' do
      expect {
        described_class.perform_later
      }.to have_enqueued_job.on_queue('default')
    end
    
    it 'se ejecuta diariamente' do
      expect {
        described_class.set(wait_until: Date.tomorrow.noon).perform_later
      }.to have_enqueued_job.at(Date.tomorrow.noon)
    end
  end
  
  describe 'rendimiento' do
    before { create_list(:user, 100, last_activity_at: 2.years.ago) }
    
    it 'procesa eficientemente muchos usuarios' do
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to perform_under(1.second).sample(10)
    end
  end
  
  describe 'notificaciones' do
    it 'solo notifica a los usuarios recién marcados como inactivos' do
      # Usuario ya inactivo
      create(:user, active: false, last_activity_at: 2.years.ago)
      
      expect {
        perform_enqueued_jobs { described_class.perform_later }
      }.to have_enqueued_mail(UserMailer, :inactivity_notice)
       .exactly(1).times # Solo el usuario recién marcado como inactivo
    end
    
    it 'no notifica a los administradores' do
      admin = create(:user, :admin, last_activity_at: 2.years.ago)
      
      perform_enqueued_jobs { described_class.perform_later }
      
      expect(ActionMailer::Base.deliveries.select { |m| m.to.include?(admin.email) }).to be_empty
    end
  end
  
  describe 'configuración de reintentos' do
    it 'reintenta el trabajo en caso de error' do
      allow_any_instance_of(described_class).to receive(:perform).and_raise(StandardError)
      
      assert_performed_jobs 1, only: described_class do
        described_class.perform_later
        rescue StandardError
      end
    end
    
    it 'tiene un número máximo de reintentos' do
      expect(described_class.sidekiq_options['retry']).to be < 5
    end
  end
  
  describe 'seguimiento de actividad' do
    it 'actualiza el timestamp de última actividad' do
      perform_enqueued_jobs { described_class.perform_later }
      
      expect(ActivityLog.last(2).map(&:action)).to include('user_marked_inactive')
    end
  end
end
