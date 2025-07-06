# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserActivityJob, type: :job do
  include ActiveJob::TestHelper
  
  let(:user) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:inactive_user) { create(:user, :inactive) }
  
  describe '#perform' do
    context 'cuando se ejecuta el trabajo' do
      before do
        # Crear algunas actividades recientes
        create_list(:activity, 3, user: user, created_at: 1.day.ago)
        create_list(:activity, 2, user: admin, created_at: 1.day.ago)
        
        # Actividad antigua (más de 30 días)
        create(:activity, user: user, created_at: 31.days.ago)
      end
      
      it 'registra la actividad del usuario' do
        expect {
          UserActivityJob.perform_now(user.id, 'inicio_sesion', { ip: '127.0.0.1' })
        }.to change(user.activities, :count).by(1)
        
        activity = user.activities.last
        expect(activity.action).to eq('inicio_sesion')
        expect(activity.metadata['ip']).to eq('127.0.0.1')
      end
      
      it 'limpia actividades antiguas' do
        expect {
          UserActivityJob.perform_now(user.id, 'nueva_actividad')
        }.to change(Activity, :count).by(0) # +1 nueva, -1 antigua = 0
        
        # Verificar que la actividad antigua fue eliminada
        expect(Activity.where('created_at < ?', 30.days.ago).count).to eq(0)
      end
      
      it 'actualiza last_activity_at del usuario' do
        freeze_time do
          expect {
            UserActivityJob.perform_now(user.id, 'nueva_actividad')
          }.to change { user.reload.last_activity_at }.to(Time.current)
        end
      end
      
      it 'no actualiza last_activity_at si el usuario está inactivo' do
        expect {
          UserActivityJob.perform_now(inactive_user.id, 'nueva_actividad')
        }.not_to change { inactive_user.reload.last_activity_at }
      end
      
      it 'maneja usuarios no encontrados' do
        expect {
          UserActivityJob.perform_now(-1, 'nueva_actividad')
        }.not_to raise_error
      end
    end
    
    context 'con notificaciones' do
      it 'envía notificación de inactividad' do
        # Configurar el usuario para que no tenga actividad reciente
        user.update_column(:last_activity_at, 8.days.ago)
        
        expect {
          UserActivityJob.perform_now(user.id, 'inicio_sesion')
        }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
          .with('UserMailer', 'inactivity_notice', 'deliver_now', args: [user.id])
      end
      
      it 'no envía notificación si el usuario está activo' do
        user.update_column(:last_activity_at, 1.day.ago)
        
        expect {
          UserActivityJob.perform_now(user.id, 'inicio_sesion')
        }.not_to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
  end
  
  describe 'encolamiento del trabajo' do
    it 'encola el trabajo correctamente' do
      expect {
        UserActivityJob.perform_later(user.id, 'inicio_sesion')
      }.to have_enqueued_job(UserActivityJob)
        .with(user.id, 'inicio_sesion', {})
        .on_queue('default')
    end
    
    it 'maneja el reintento en caso de error' do
      allow_any_instance_of(User).to receive(:update!).and_raise(StandardError)
      
      assert_performed_jobs 1 do
        UserActivityJob.perform_later(user.id, 'error_actividad')
        perform_enqueued_jobs
      end
      
      # Verificar que el trabajo se ha programado para reintentar
      expect(UserActivityJob).to have_been_enqueued.with(user.id, 'error_actividad', {})
    end
  end
  
  describe 'rendimiento' do
    it 'procesa rápidamente la actividad del usuario' do
      expect {
        perform_enqueued_jobs do
          UserActivityJob.perform_later(user.id, 'actividad_rapida')
        end
      }.to perform_under(50).ms
    end
    
    it 'es eficiente con muchos usuarios' do
      users = create_list(:user, 100)
      
      expect {
        perform_enqueued_jobs do
          users.each do |u|
            UserActivityJob.perform_later(u.id, 'actividad_masiva')
          end
        end
      }.to perform_under(500).ms
    end
  end
  
  describe 'seguimiento de actividad' do
    it 'registra la duración de la actividad' do
      start_time = Time.current
      end_time = start_time + 5.minutes
      
      travel_to start_time do
        UserActivityJob.perform_now(user.id, 'inicio_sesion', { duration: 300 })
      end
      
      activity = user.activities.last
      expect(activity.duration).to eq(300)
      expect(activity.metadata['duration']).to eq(300)
    end
    
    it 'calcula la duración si se proporciona started_at' do
      started_at = 5.minutes.ago
      
      Timecop.freeze do
        UserActivityJob.perform_now(
          user.id, 
          'cierre_sesion', 
          { started_at: started_at.iso8601 }
        )
        
        activity = user.activities.last
        expect(activity.duration).to be_within(1).of(300)
      end
    end
  end
  
  describe 'seguimiento de ubicación' do
    it 'registra la ubicación si está disponible' do
      location_data = {
        ip: '8.8.8.8',
        city: 'Mountain View',
        country: 'US',
        latitude: 37.386,
        longitude: -122.0838
      }
      
      UserActivityJob.perform_now(
        user.id, 
        'inicio_sesion', 
        { location: location_data }
      )
      
      activity = user.activities.last
      expect(activity.metadata['location']).to eq(location_data.stringify_keys)
      expect(activity.ip_address).to eq('8.8.8.8')
    end
  end
  
  describe 'seguimiento de dispositivo' do
    it 'registra información del dispositivo' do
      device_info = {
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        device_type: 'desktop',
        os: 'Windows 10',
        browser: 'Chrome',
        screen_resolution: '1920x1080'
      }
      
      UserActivityJob.perform_now(
        user.id, 
        'inicio_sesion', 
        { device: device_info }
      )
      
      activity = user.activities.last
      expect(activity.metadata['device']).to eq(device_info.stringify_keys)
      expect(activity.user_agent).to eq(device_info[:user_agent])
    end
  end
  
  describe 'validaciones' do
    it 'ignora acciones no válidas' do
      expect {
        UserActivityJob.perform_now(user.id, 'accion_invalida')
      }.not_to raise_error
      
      expect(user.activities.last.action).to eq('accion_invalida')
    end
    
    it 'valida los metadatos' do
      metadata = { sensitive: 'datos sensibles' }
      
      expect {
        UserActivityJob.perform_now(user.id, 'con_metadatos', metadata)
      }.to raise_error(ActiveModel::ValidationError, /No se permiten metadatos sensibles/)
    end
  end
  
  describe 'métodos de clase' do
    describe '.track' do
      it 'encola un trabajo de seguimiento de actividad' do
        expect {
          UserActivityJob.track(user, 'accion_personalizada', { custom: 'data' })
        }.to have_enqueued_job(UserActivityJob)
          .with(user.id, 'accion_personalizada', { 'custom' => 'data' })
      end
      
      it 'permite encolar para ejecución posterior' do
        time = 1.hour.from_now
        
        expect {
          UserActivityJob.track(user, 'accion_programada', {}, wait_until: time)
        }.to have_enqueued_job(UserActivityJob)
          .at(time)
      end
    end
  end
  
  describe 'manejo de errores' do
    it 'registra errores en el log' do
      allow(Rails.logger).to receive(:error)
      allow_any_instance_of(User).to receive(:update!).and_raise(StandardError.new('Error de prueba'))
      
      UserActivityJob.perform_now(user.id, 'accion_con_error')
      
      expect(Rails.logger).to have_received(:error).with(/Error al registrar actividad/)
    end
    
    it 'no propaga excepciones para evitar fallos en segundo plano' do
      allow_any_instance_of(User).to receive(:update!).and_raise(StandardError)
      
      expect {
        UserActivityJob.perform_now(user.id, 'accion_con_error')
      }.not_to raise_error
    end
  end
  
  describe 'métricas y análisis' do
    before do
      # Configurar métricas para la prueba
      allow(StatsD).to receive(:increment)
      allow(StatsD).to receive(:measure)
    end
    
    it 'registra métricas de actividad' do
      UserActivityJob.perform_now(user.id, 'inicio_sesion')
      
      expect(StatsD).to have_received(:increment).with('user_activity.inicio_sesion')
      expect(StatsD).to have_received(:measure).with('user_activity.duration', kind_of(Numeric))
    end
    
    it 'registra el tiempo de procesamiento' do
      UserActivityJob.perform_now(user.id, 'inicio_sesion')
      
      expect(StatsD).to have_received(:measure)
        .with('user_activity_job.process', kind_of(Numeric), tags: ['action:inicio_sesion'])
    end
  end
  
  describe 'pruebas de integración con ActiveJob' do
    it 'se integra correctamente con el sistema de colas' do
      expect {
        UserActivityJob.perform_later(user.id, 'actividad_en_cola')
      }.to have_enqueued_job(UserActivityJob)
        .with(user.id, 'actividad_en_cola', {})
        .on_queue('default')
    end
    
    it 'maneja la prioridad de la cola' do
      expect {
        UserActivityJob.set(queue: 'high_priority', wait: 5.minutes)
                     .perform_later(user.id, 'actividad_prioritaria')
      }.to have_enqueued_job(UserActivityJob)
        .with(user.id, 'actividad_prioritaria', {})
        .on_queue('high_priority')
        .at(5.minutes.from_now)
    end
  end
  
  describe 'pruebas de concurrencia' do
    it 'maneja múltiples trabajos en paralelo' do
      # Desactivar el procesamiento en segundo plano para la prueba
      perform_enqueued_jobs do
        # Iniciar múltiples trabajos en paralelo
        threads = 5.times.map do |i|
          Thread.new do
            UserActivityJob.perform_later(user.id, "actividad_#{i}")
          end
        end
        
        # Esperar a que todos los hilos terminen
        threads.each(&:join)
      end
      
      # Verificar que se crearon todas las actividades
      expect(user.activities.count).to eq(5)
      
      # Verificar que no hay duplicados
      activity_actions = user.activities.pluck(:action).sort
      expect(activity_actions).to eq((0..4).map { |i| "actividad_#{i}" }.sort)
    end
  end
end
