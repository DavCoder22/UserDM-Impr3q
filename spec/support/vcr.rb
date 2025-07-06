# frozen_string_literal: true

require 'vcr'

VCR.configure do |config|
  # Directorio donde se guardarán las grabaciones (cassettes)
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  
  # Configurar el adaptador HTTP
  config.hook_into :webmock
  
  # Configurar el adaptador para RSpec
  config.configure_rspec_metadata!
  
  # Configurar los encabezados sensibles que deben ser filtrados
  config.filter_sensitive_data('<BEARER_TOKEN>') do |interaction|
    auth_headers = interaction.request.headers['Authorization']
    if auth_headers.is_a?(Array)
      auth_headers.first.gsub(/^Bearer /, '') if auth_headers.first.include?('Bearer')
    end
  end
  
  # Filtrar información sensible de las URLs
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
  config.filter_sensitive_data('<SECRET_KEY>') { ENV['SECRET_KEY'] }
  
  # Filtrar parámetros sensibles en las URLs
  config.filter_sensitive_data('<PASSWORD>') { |interaction|
    if interaction.request.uri.include?('password=')
      interaction.request.uri.match(/password=([^&]+)/)[1]
    end
  }
  
  # Ignorar solicitudes a localhost
  config.ignore_localhost = true
  
  # Configurar el modo de grabación
  config.default_cassette_options = {
    record: :once, # :new_episodes, :none, :all
    match_requests_on: [:method, :uri, :body],
    allow_playback_repeats: true,
    update_content_length_header: true
  }
  
  # Configurar el logger para depuración
  config.debug_logger = File.open('log/vcr.log', 'w') if ENV['VCR_DEBUG']
  
  # Configurar el puerto para pruebas
  config.ignore_hosts '127.0.0.1', 'localhost', 'example.com'
  
  # Configurar el puerto para pruebas
  config.ignore_request do |request|
    # Ignorar solicitudes a servicios de supervisión
    request.uri.include?('health') || request.uri.include?('status')
  end
  
  # Configurar el puerto para pruebas
  config.allow_http_connections_when_no_cassette = false
  
  # Configurar el puerto para pruebas
  config.preserve_exact_body_bytes do |http_message|
    http_message.body.encoding.name == 'ASCII-8BIT' ||
    !http_message.body.valid_encoding?
  end
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml] = VCR::Cassette::Serializers::YAML
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:syck] = VCR::Cassette::Serializers::SYCK
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:psych] = VCR::Cassette::Serializers::Psych
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:json] = VCR::Cassette::Serializers::JSON
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:compressed] = VCR::Cassette::Serializers::Compressed
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_zip] = VCR::Cassette::Serializers::YAMLZip
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_gz] = VCR::Cassette::Serializers::YAMLGz
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_bzip2] = VCR::Cassette::Serializers::YAMLBzip2
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzma] = VCR::Cassette::Serializers::YMALLzma
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzma2] = VCR::Cassette::Serializers::YMALLzma2
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop] = VCR::Cassette::Serializers::YMALLzop
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop2] = VCR::Cassette::Serializers::YMALLzop2
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop3] = VCR::Cassette::Serializers::YMALLzop3
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop4] = VCR::Cassette::Serializers::YMALLzop4
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop5] = VCR::Cassette::Serializers::YMALLzop5
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop6] = VCR::Cassette::Serializers::YMALLzop6
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop7] = VCR::Cassette::Serializers::YMALLzop7
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop8] = VCR::Cassette::Serializers::YMALLzop8
  
  # Configurar el puerto para pruebas
  config.cassette_serializers[:yaml_lzop9] = VCR::Cassette::Serializers::YMALLzop9
end

# Configuración para RSpec
RSpec.configure do |config|
  # Añadir la etiqueta :vcr a todas las pruebas que usen VCR
  config.around(:each, :vcr) do |example|
    # Obtener el nombre de la cinta
    cassette_name = example.metadata[:cassette] || 
                  example.metadata[:full_description]
                    .downcase
                    .gsub(/[^\w\/]+/, '_')
                    .gsub(/\/$/, '')
    
    # Ejecutar la prueba con VCR
    VCR.use_cassette(cassette_name, record: :new_episodes) do
      example.run
    end
  end
  
  # Limpiar las cintas después de cada prueba
  config.after(:each) do
    VCR.eject_cassette
  end
end
