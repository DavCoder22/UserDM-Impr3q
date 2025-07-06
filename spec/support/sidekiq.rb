# frozen_string_literal: true

require 'sidekiq/testing'

# Configuración de Sidekiq para pruebas
RSpec.configure do |config|
  # Limpiar los trabajos de Sidekiq antes de cada prueba
  config.before(:each) do
    Sidekiq::Worker.clear_all
    
    # Configurar el modo de prueba en línea (ejecutar trabajos inmediatamente)
    Sidekiq::Testing.inline! if example.metadata[:sidekiq_inline]
    
    # Configurar el modo de prueba en falso (no ejecutar trabajos)
    Sidekiq::Testing.fake! if example.metadata[:sidekiq_fake]
  end
  
  # Configurar Sidekiq para ejecutar trabajos inmediatamente en pruebas de sistema
  config.before(:each, type: :system) do |example|
    unless example.metadata[:sidekiq_fake]
      Sidekiq::Testing.inline!
    end
  end
  
  # Configurar Sidekiq para usar Redis de prueba
  config.before(:suite) do
    # Limpiar Redis antes de ejecutar las pruebas
    Sidekiq.redis(&:flushdb)
  end
  
  # Configurar Sidekiq para limpiar Redis después de cada prueba
  config.after(:each) do
    Sidekiq.redis(&:flushdb)
  end
  
  # Método de ayuda para probar trabajos en cola
  def enqueued_jobs_for(worker_class)
    Sidekiq::Queues[worker_class.sidekiq_options['queue'].to_s]
      .select { |job| job['class'] == worker_class.to_s }
  end
  
  # Método de ayuda para probar trabajos programados
  def scheduled_jobs_for(worker_class)
    Sidekiq::ScheduledSet.new
      .select { |job| job.klass == worker_class.to_s }
  end
  
  # Método de ayuda para probar trabajos retenidos
  def retry_jobs_for(worker_class)
    Sidekiq::RetrySet.new
      .select { |job| job.klass == worker_class.to_s }
  end
  
  # Método de ayuda para probar trabajos fallidos
  def failed_jobs_for(worker_class)
    Sidekiq::DeadSet.new
      .select { |job| job.klass == worker_class.to_s }
  end
  
  # Método de ayuda para probar trabajos en proceso
  def processing_jobs_for(worker_class)
    Sidekiq::Workers.new
      .select { |_process_id, _thread_id, work| work['payload']['class'] == worker_class.to_s }
  end
  
  # Método de ayuda para probar trabajos en cola
  def assert_job_enqueued(worker_class, *args)
    expect(Sidekiq::Queues[worker_class.sidekiq_options['queue'].to_s])
      .to include(hash_including('class' => worker_class.to_s, 'args' => args))
  end
  
  # Método de ayuda para probar trabajos programados
  def assert_job_scheduled(worker_class, *args, at: nil)
    jobs = Sidekiq::ScheduledSet.new
      .select { |job| job.klass == worker_class.to_s && job.args == args }
      
    if at
      jobs = jobs.select { |job| job.at.to_i == at.to_i }
    end
    
    expect(jobs.size).to eq(1)
  end
  
  # Método de ayuda para probar trabajos retenidos
  def assert_job_retried(worker_class, *args)
    jobs = Sidekiq::RetrySet.new
      .select { |job| job.klass == worker_class.to_s && job.args == args }
    
    expect(jobs.size).to eq(1)
  end
  
  # Método de ayuda para probar trabajos fallidos
  def assert_job_failed(worker_class, *args)
    jobs = Sidekiq::DeadSet.new
      .select { |job| job.klass == worker_class.to_s && job.args == args }
    
    expect(jobs.size).to eq(1)
  end
  
  # Método de ayuda para probar trabajos en proceso
  def assert_job_processing(worker_class, *args)
    jobs = Sidekiq::Workers.new
      .select { |_process_id, _thread_id, work| 
        work['payload']['class'] == worker_class.to_s && 
        work['payload']['args'] == args 
      }
    
    expect(jobs.size).to eq(1)
  end
  
  # Método de ayuda para probar que no hay trabajos en cola
  def assert_no_jobs_enqueued(worker_class = nil)
    if worker_class
      expect(Sidekiq::Queues[worker_class.sidekiq_options['queue'].to_s])
        .to be_empty
    else
      Sidekiq::Queues.each_value do |queue|
        expect(queue).to be_empty
      end
    end
  end
  
  # Método de ayuda para probar que no hay trabajos programados
  def assert_no_jobs_scheduled(worker_class = nil)
    if worker_class
      jobs = Sidekiq::ScheduledSet.new
        .select { |job| job.klass == worker_class.to_s }
      
      expect(jobs).to be_empty
    else
      expect(Sidekiq::ScheduledSet.new.size).to eq(0)
    end
  end
  
  # Método de ayuda para probar que no hay trabajos retenidos
  def assert_no_jobs_retried(worker_class = nil)
    if worker_class
      jobs = Sidekiq::RetrySet.new
        .select { |job| job.klass == worker_class.to_s }
      
      expect(jobs).to be_empty
    else
      expect(Sidekiq::RetrySet.new.size).to eq(0)
    end
  end
  
  # Método de ayuda para probar que no hay trabajos fallidos
  def assert_no_jobs_failed(worker_class = nil)
    if worker_class
      jobs = Sidekiq::DeadSet.new
        .select { |job| job.klass == worker_class.to_s }
      
      expect(jobs).to be_empty
    else
      expect(Sidekiq::DeadSet.new.size).to eq(0)
    end
  end
  
  # Método de ayuda para probar que no hay trabajos en proceso
  def assert_no_jobs_processing(worker_class = nil)
    if worker_class
      jobs = Sidekiq::Workers.new
        .select { |_process_id, _thread_id, work| work['payload']['class'] == worker_class.to_s }
      
      expect(jobs).to be_empty
    else
      expect(Sidekiq::Workers.new.size).to eq(0)
    end
  end
end
