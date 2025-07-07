require 'factory_bot'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  
  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

# Configuración específica para FactoryBot con Sinatra
FactoryBot.define do
  to_create { |instance| instance.save($db_connection) }
end
