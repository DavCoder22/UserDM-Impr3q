# frozen_string_literal: true

require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

# Configuración de Capybara
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[headless disable-gpu no-sandbox disable-dev-shm-usage]
  )
  
  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    options: options
  )
end

# Configuración para pruebas de sistema
RSpec.configure do |config|
  # Driver predeterminado para pruebas de sistema
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  
  # Configuración para pruebas de JavaScript
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
  
  # Configuración para capturas de pantalla
  config.after(:each, type: :system) do |example|
    if example.exception
      # Tomar captura de pantalla en caso de fallo
      timestamp = Time.current.strftime('%Y%m%d%H%M%S')
      screenshot_name = "screenshot-#{timestamp}-#{example.full_description.parameterize}.png"
      page.save_screenshot(Rails.root.join('tmp', 'screenshots', screenshot_name))
      
      # Guardar el HTML de la página
      html_name = "page-#{timestamp}-#{example.full_description.parameterize}.html"
      File.write(
        Rails.root.join('tmp', 'screenshots', html_name),
        page.html
      )
      
      # Mostrar la ruta de la captura de pantalla
      puts "Screenshot: tmp/screenshots/#{screenshot_name}"
      puts "HTML: tmp/screenshots/#{html_name}"
    end
  end
  
  # Configuración para pruebas de sistema con autenticación
  config.include Warden::Test::Helpers, type: :system
  
  # Limpiar sesiones después de cada prueba
  config.after(:each, type: :system) do
    Warden.test_reset!
  end
  
  # Configuración para pruebas con Devise
  config.include Devise::Test::IntegrationHelpers, type: :system
  
  # Configuración para pruebas con FactoryBot
  config.include FactoryBot::Syntax::Methods
  
  # Configuración para pruebas con DatabaseCleaner
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end
  
  config.before(:each) do
    DatabaseCleaner.strategy = :transaction
  end
  
  config.before(:each, type: :system) do
    DatabaseCleaner.strategy = :truncation
  end
  
  config.before(:each) do
    DatabaseCleaner.start
  end
  
  config.after(:each) do
    DatabaseCleaner.clean
  end
  
  # Configuración para pruebas con VCR
  config.around(:each, :vcr) do |example|
    VCR.use_cassette(example.metadata[:vcr]) do
      example.run
    end
  end
  
  # Configuración para pruebas con Timecop
  config.around(:each, :freeze_time) do |example|
    Timecop.freeze(Time.current) do
      example.run
    end
  end
  
  # Configuración para pruebas con Sidekiq
  config.before(:each, :sidekiq_inline) do
    Sidekiq::Testing.inline!
  end
  
  config.after(:each, :sidekiq_inline) do
    Sidekiq::Testing.fake!
  end
  
  # Configuración para pruebas con WebMock
  config.before(:each, :webmock) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
  
  # Configuración para pruebas con FactoryBot
  config.before(:suite) do
    FactoryBot.find_definitions
  end
  
  # Configuración para pruebas con Shoulda Matchers
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  
  # Configuración para pruebas con Rack::Test
  config.include Rack::Test::Methods, type: :request
  
  # Configuración para pruebas con Devise
  config.include Devise::Test::IntegrationHelpers, type: :request
  
  # Configuración para pruebas con ActionMailer
  config.include ActionMailer::TestHelper, type: :mailer
  
  # Configuración para pruebas con ActiveJob
  config.include ActiveJob::TestHelper, type: :job
  
  # Configuración para pruebas con ActionCable
  config.include ActionCable::TestHelper, type: :channel
  
  # Configuración para pruebas con ActionText
  config.include ActionText::TestHelper, type: :system
  
  # Configuración para pruebas con ActiveStorage
  config.include ActiveSupport::Testing::FileFixtures, type: :system
  
  # Configuración para pruebas con ViewComponent
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  
  # Configuración para pruebas con ViewComponent::TestCase
  config.include ViewComponent::TestCase::Behavior, type: :component
  
  # Configuración para pruebas con ViewComponent::SystemTestHelpers
  config.include ViewComponent::SystemTestHelpers, type: :component
  
  # Configuración para pruebas con ViewComponent::Preview::TestCase
  config.include ViewComponent::Preview::TestCase::Behavior, type: :preview
  
  # Configuración para pruebas con ViewComponent::Preview::SystemTestHelpers
  config.include ViewComponent::Preview::SystemTestHelpers, type: :preview
end
