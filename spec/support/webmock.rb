require 'webmock/rspec'

# Bloquear todas las solicitudes HTTP externas por defecto
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['elasticsearch', 'redis', 'postgres', 'chrome']
)

# Configuración para permitir solicitudes a localhost
RSpec.configure do |config|
  config.before(:each) do
    # Permitir solicitudes a localhost
    WebMock.disable_net_connect!(
      allow_localhost: true,
      allow: ['elasticsearch', 'redis', 'postgres', 'chrome']
    )
    
    # Configurar stubs comunes aquí si es necesario
    # Ejemplo:
    # stub_request(:post, 'https://api.externa.com/auth')
    #   .to_return(status: 200, body: '{"token":"abc123"}', headers: { 'Content-Type': 'application/json' })
  end
end
