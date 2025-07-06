# frozen_string_literal: true

# Configuración para Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Elige un framework de pruebas
    with.test_framework :rspec

    # Incluye los helpers para el framework de pruebas
    with.library :rails

    # O incluye solo los helpers que necesites
    # with.library :active_record
    # with.library :active_model
    # with.library :action_controller
    # with.library :active_storage
    # with.library :active_job
  end
end

# Configuración personalizada para los matchers
RSpec.configure do |config|
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  config.include(Shoulda::Matchers::ActionController, type: :controller)
  
  # Configuración para validaciones de modelo
  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
  
  # Configuración para asociaciones de modelo
  Shoulda::Matchers::ActiveRecord::Model.macros.each do |macro|
    config.include Shoulda::Matchers::ActiveRecord, type: :model
    config.include Shoulda::Matchers::ActiveModel, type: :model
  end
  
  # Configuración para controladores
  config.include Shoulda::Matchers::ActionController, type: :controller
  
  # Configuración para rutas
  config.include Shoulda::Matchers::ActionController::RouteHelpers, type: :routing
  
  # Configuración para vistas
  config.include Shoulda::Matchers::ActionController::TemplateAssertions, type: :view
  
  # Configuración para helpers
  config.include Shoulda::Matchers::ActionController::Helpers, type: :helper
  
  # Configuración para mailers
  config.include Shoulda::Matchers::ActionMailer, type: :mailer
  
  # Configuración para jobs
  config.include Shoulda::Matchers::ActiveJob, type: :job
  
  # Configuración para system tests
  config.include Shoulda::Matchers::System, type: :system
  
  # Configuración para request specs
  config.include Shoulda::Matchers::ActionDispatch, type: :request
  
  # Configuración para feature specs
  config.include Shoulda::Matchers::Capybara, type: :feature
  
  # Configuración para view specs
  config.include Shoulda::Matchers::ActionView, type: :view
  
  # Configuración para helper specs
  config.include Shoulda::Matchers::ActionView::Helper, type: :helper
  
  # Configuración para mailer specs
  config.include Shoulda::Matchers::ActionMailer, type: :mailer
  
  # Configuración para job specs
  config.include Shoulda::Matchers::ActiveJob, type: :job
  
  # Configuración para system specs
  config.include Shoulda::Matchers::System, type: :system
  
  # Configuración para request specs
  config.include Shoulda::Matchers::ActionDispatch, type: :request
  
  # Configuración para feature specs
  config.include Shoulda::Matchers::Capybara, type: :feature
end
