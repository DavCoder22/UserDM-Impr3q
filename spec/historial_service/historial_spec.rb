require 'spec_helper'
require 'httparty'

RSpec.describe 'Historial Service' do
  include Rack::Test::Methods
  
  let(:base_url) { TestConfig::HISTORIAL_SERVICE_URL }
  let(:auth_url) { TestConfig::AUTH_SERVICE_URL }
  let(:test_user) { attributes_for(:user) }
  let(:test_events) { build_list(:history_event, 5, email: test_user[:email]) }
  
  before(:all) do
    # Registrar un usuario para pruebas
    @test_user = attributes_for(:user)
    HTTParty.post(
      "#{auth_url}/register",
      body: @test_user.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    # Obtener token de autenticación
    login_response = HTTParty.post(
      "#{auth_url}/login",
      body: { email: @test_user[:email], password: @test_user[:password] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
    
    @auth_token = JSON.parse(login_response.body)['token']
    
    # Crear algunos eventos de prueba
    @test_events = Array.new(5) do |i|
      event = build(
        :history_event, 
        email: @test_user[:email],
        created_at: (Time.now - (i * 3600)).utc.iso8601
      )
      
      HTTParty.post(
        "#{base_url}/events",
        body: event.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      event
    end
  end
  
  describe 'POST /events' do
    let(:new_event) { build(:history_event, email: @test_user[:email]) }
    
    it 'registra un nuevo evento' do
      response = HTTParty.post(
        "#{base_url}/events",
        body: new_event.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      expect(response.code).to eq(201)
      json_response = JSON.parse(response.body)
      expect(json_response).to include('id', 'event_type', 'created_at')
      expect(json_response['event_type']).to eq(new_event[:event_type])
    end
    
    it 'requiere autenticación' do
      response = HTTParty.post(
        "#{base_url}/events",
        body: new_event.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      expect(response.code).to eq(401)
    end
  end
  
  describe 'GET /events' do
    it 'obtiene el historial de eventos del usuario' do
      response = HTTParty.get(
        "#{base_url}/events",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.size).to be >= 5 # Debería incluir los eventos de prueba
      
      # Verificar que los eventos pertenecen al usuario
      json_response.each do |event|
        expect(event['email']).to eq(@test_user[:email])
      end
    end
    
    it 'permite filtrar por tipo de evento' do
      # Crear un evento de un tipo específico para probar el filtro
      event_type = 'test_event_type'
      HTTParty.post(
        "#{base_url}/events",
        body: build(:history_event, email: @test_user[:email], event_type: event_type).to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      response = HTTParty.get(
        "#{base_url}/events?event_type=#{event_type}",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      
      # Todos los eventos devueltos deben ser del tipo solicitado
      json_response.each do |event|
        expect(event['event_type']).to eq(event_type)
      end
    end
    
    it 'permite paginar los resultados' do
      limit = 2
      response = HTTParty.get(
        "#{base_url}/events?limit=#{limit}&offset=0",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response.size).to be <= limit
    end
  end
  
  describe 'GET /events/:id' do
    let(:event_id) do
      # Obtener el ID del primer evento de prueba
      response = HTTParty.get(
        "#{base_url}/events",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      JSON.parse(response.body).first['id']
    end
    
    it 'obtiene un evento específico por ID' do
      response = HTTParty.get(
        "#{base_url}/events/#{event_id}",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response['id']).to eq(event_id)
      expect(json_response['email']).to eq(@test_user[:email])
    end
    
    it 'devuelve 404 para un ID inexistente' do
      response = HTTParty.get(
        "#{base_url}/events/nonexistent_id",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(404)
    end
    
    it 'no permite acceder a eventos de otros usuarios' do
      # Crear un segundo usuario
      other_user = attributes_for(:user)
      HTTParty.post(
        "#{auth_url}/register",
        body: other_user.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      # Obtener token del segundo usuario
      login_response = HTTParty.post(
        "#{auth_url}/login",
        body: { email: other_user[:email], password: other_user[:password] }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      other_token = JSON.parse(login_response.body)['token']
      
      # Intentar acceder al evento del primer usuario
      response = HTTParty.get(
        "#{base_url}/events/#{event_id}",
        headers: { 'Authorization' => "Bearer #{other_token}" }
      )
      
      expect(response.code).to eq(404)
    end
  end
  
  describe 'DELETE /events/:id' do
    let(:event_to_delete) do
      # Crear un evento para eliminarlo
      event = build(:history_event, email: @test_user[:email])
      
      response = HTTParty.post(
        "#{base_url}/events",
        body: event.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      JSON.parse(response.body)
    end
    
    it 'elimina un evento existente' do
      response = HTTParty.delete(
        "#{base_url}/events/#{event_to_delete['id']}",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(response.code).to eq(200)
      
      # Verificar que el evento ya no existe
      get_response = HTTParty.get(
        "#{base_url}/events/#{event_to_delete['id']}",
        headers: { 'Authorization' => "Bearer #{@auth_token}" }
      )
      
      expect(get_response.code).to eq(404)
    end
  end
  
  describe 'GraphQL API' do
    it 'ejecuta consultas GraphQL' do
      query = <<~GQL
        query {
          events(email: "#{@test_user[:email]}", limit: 5) {
            id
            event_type
            created_at
          }
        }
      GQL
      
      response = HTTParty.post(
        "#{base_url}/graphql",
        body: { query: query }.to_json,
        headers: { 
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{@auth_token}"
        }
      )
      
      expect(response.code).to eq(200)
      json_response = JSON.parse(response.body)
      expect(json_response).to have_key('data')
      expect(json_response['data']).to have_key('events')
      expect(json_response['data']['events']).to be_an(Array)
    end
  end
end
