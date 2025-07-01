require 'sinatra'
require 'json'
require 'jwt'
require 'sequel'
require 'graphql'
require_relative 'types'

# Definir el esquema GraphQL
class QueryType < Types::QueryType
end

class Schema < GraphQL::Schema
  query QueryType
end

# Configuración de la base de datos
DB = if ENV['DB_ADAPTER'] == 'sqlite'
       require 'sqlite3'
       Sequel.sqlite(ENV.fetch('DB_DATABASE', ':memory:')).tap do |db|
         # Crear tabla de eventos si no existe
         unless db.table_exists?(:events)
           db.create_table :events do
             primary_key :id
             String :email, null: false
             String :event_type, null: false
             String :payload, text: true
             DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
           end
         end
       end
     else
       # Configuración para PostgreSQL
       require 'pg'
       db = Sequel.connect(
         adapter: 'postgres',
         host: ENV.fetch('DB_HOST', 'localhost'),
         port: ENV.fetch('DB_PORT', '5432'),
         database: ENV.fetch('DB_NAME', 'user_history_dev'),
         user: ENV.fetch('DB_USER', 'postgres'),
         password: ENV.fetch('DB_PASSWORD', 'postgres')
       )
       
       # Asegurarse de que la extensión pg_json esté disponible
       begin
         db.extension :pg_json
         
         # Crear tabla de eventos si no existe
         unless db.table_exists?(:events)
           db.create_table :events do
             primary_key :id
             String :email, null: false
             String :event_type, null: false
             column :payload, :jsonb
             DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
           end
         end
       rescue => e
         puts "Advertencia: #{e.message}"
       end
       
       db
     end

after do
  content_type :json
end

helpers do
  def json_body
    request.body.rewind
    JSON.parse(request.body.read) rescue {}
  end

  def authorized_email
    auth_header = request.env['HTTP_AUTHORIZATION']
    halt 401, { error: 'Falta header Authorization' }.to_json unless auth_header&.start_with?('Bearer ')
    token = auth_header.split.last
    begin
      decoded = JWT.decode(token, ENV.fetch('JWT_PUBLIC_KEY', nil), false, verify: false)
      decoded.first['email']
    rescue JWT::DecodeError
      halt 401, { error: 'Token no válido' }.to_json
    end
  end
end

unless DB.table_exists?(:events)
  DB.create_table :events do
    primary_key :id
    String :email, null: false
    String :event_type, null: false
    Jsonb  :payload
    DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
  end
end

EVENTS = DB[:events]

# Endpoint GraphQL
post '/graphql' do
  request.body.rewind
  query = params[:query] || JSON.parse(request.body.read, symbolize_names: true)[:query]
  
  result = Schema.execute(
    query,
    variables: params[:variables] || {},
    context: { current_user: authorized_email }
  )
  
  content_type :json
  result.to_json
end

post '/events' do
  email = authorized_email
  data = json_body
  type = data['event_type']
  halt 400, { error: 'event_type requerido' }.to_json unless type
  id = EVENTS.insert(email: email, event_type: type, payload: data['payload'])
  status 201
  { id: id }.to_json
end

get '/events' do
  email = authorized_email
  type = params['type']
  query = EVENTS.where(email: email)
  query = query.where(event_type: type) if type
  query.all.to_json
end

get '/events/:id' do |id|
  email = authorized_email
  event = EVENTS.where(id: id, email: email).first
  halt 404, { error: 'No encontrado' }.to_json unless event
  event.to_json
end
