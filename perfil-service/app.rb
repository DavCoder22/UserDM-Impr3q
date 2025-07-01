require 'sinatra'
require 'json'
require 'jwt'
require 'dotenv/load'
require 'httparty'
require 'securerandom'
require 'bcrypt'

# Cargar configuración de la base de datos y modelos
require_relative 'config/database'

# Configuración de la aplicación
set :bind, ENV.fetch('HOST', '0.0.0.0')
set :port, ENV.fetch('PORT', 4567)
set :environment, ENV.fetch('RACK_ENV', 'development').to_sym
set :show_exceptions, :after_handler

# Configuración para desarrollo
configure :development do
  require 'sinatra/reloader'
  also_reload 'models/*.rb'
  also_reload 'config/*.rb'
  
  use Rack::CommonLogger, $stdout
  $stdout.sync = true
end

# Configuración general
configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET', SecureRandom.hex(64))
  set :protection, except: [:json_csrf]
  
  # Configuración de CORS
  set :allow_origin, ENV.fetch('ALLOW_ORIGIN', '*')
  set :allow_methods, %i[get post put delete options]
  set :allow_credentials, true
  set :max_age, '1728000'
  set :expose_headers, %w[Authorization]
end

# Middleware para manejo de CORS
before do
  response.headers['Access-Control-Allow-Origin'] = settings.allow_origin
  response.headers['Access-Control-Allow-Methods'] = settings.allow_methods.join(',')
  response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
  response.headers['Access-Control-Allow-Credentials'] = 'true' if settings.allow_credentials
  response.headers['Access-Control-Max-Age'] = settings.max_age
  response.headers['Access-Control-Expose-Headers'] = settings.expose_headers.join(',')
  
  # Responder inmediatamente a las peticiones OPTIONS
  halt 200 if request.request_method == 'OPTIONS'
  
  content_type :json
end

# Helpers
helpers do
  # Parsear el cuerpo de la petición JSON
  def json_body
    @json_body ||= begin
      request.body.rewind
      JSON.parse(request.body.read) rescue {}
    end
  end
  
  # Obtener el usuario autenticado desde el token JWT
  def current_user
    return @current_user if defined?(@current_user)
    
    auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header&.gsub(/^Bearer\s+/, '')
    
    return nil unless token
    
    begin
      # Verificar el token con el auth-service
      response = HTTParty.get(
        "#{ENV['AUTH_SERVICE_URL']}/api/v1/auth/me",
        headers: { 'Authorization' => "Bearer #{token}" }
      )
      
      if response.success?
        @current_user = JSON.parse(response.body, symbolize_names: true)
      else
        nil
      end
    rescue => e
      puts "Error al validar token: #{e.message}"
      nil
    end
  end
  
  # Verificar autenticación
  def authenticate!
    halt 401, { error: 'No autorizado' }.to_json unless current_user
  end
  
  # Verificar rol de administrador
  def admin_only!
    authenticate!
    halt 403, { error: 'Acceso denegado' }.to_json unless current_user[:rol] == 'admin'
  end
  
  # Respuesta de error estándar
  def error_response(status, message, details = nil)
    response = { error: message }
    response[:details] = details if details
    halt status, response.to_json
  end
  
  # Respuesta exitosa estándar
  def json_response(data, status = 200)
    status status
    data.to_json
  end
end

# Endpoints para perfiles

# Obtener el perfil del usuario actual
get '/api/v1/profile' do
  authenticate!
  
  profile = Profile.find(user_id: current_user[:id])
  if profile
    json_response(profile.to_api)
  else
    error_response(404, 'Perfil no encontrado')
  end
end

# Crear o actualizar el perfil del usuario actual
put '/api/v1/profile' do
  authenticate!
  
  profile_data = json_body
  
  # Validar datos requeridos
  required_fields = ['nombre_completo', 'correo']
  missing_fields = required_fields.select { |field| profile_data[field].to_s.empty? }
  
  unless missing_fields.empty?
    error_response(400, "Faltan campos requeridos: #{missing_fields.join(', ')}")
  end
  
  # Buscar perfil existente o crear uno nuevo
  profile = Profile.find(user_id: current_user[:id]) || Profile.new(user_id: current_user[:id])
  
  # Actualizar atributos
  profile.update(
    nombre_completo: profile_data['nombre_completo'],
    correo: profile_data['correo'].downcase,
    telefono: profile_data['telefono'],
    direccion: profile_data['direccion'],
    fecha_nacimiento: profile_data['fecha_nacimiento'],
    genero: profile_data['genero']
  )
  
  if profile.valid? && profile.save
    json_response(profile.to_api, profile.new? ? 201 : 200)
  else
    error_response(422, 'Error al guardar el perfil', profile.errors.full_messages)
  end
end

# Actualizar el avatar del perfil
put '/api/v1/profile/avatar' do
  authenticate!
  
  # En un entorno real, aquí se manejaría la subida de archivos
  # Por ahora, solo aceptamos una URL
  avatar_url = json_body['avatar_url']
  
  unless avatar_url
    error_response(400, 'Se requiere la URL del avatar')
  end
  
  profile = Profile.find(user_id: current_user[:id]) || Profile.new(user_id: current_user[:id])
  
  if profile.update(avatar_url: avatar_url)
    json_response(profile.to_api)
  else
    error_response(422, 'Error al actualizar el avatar', profile.errors.full_messages)
  end
end

# Obtener perfil por ID (solo administradores)
get '/api/v1/profiles/:id' do |id|
  admin_only!
  
  profile = Profile.find(id: id)
  if profile
    json_response(profile.to_api)
  else
    error_response(404, 'Perfil no encontrado')
  end
end

# Buscar perfiles (solo administradores)
get '/api/v1/profiles' do
  admin_only!
  
  query = params['q']
  page = (params['page'] || 1).to_i
  per_page = (params['per_page'] || 10).to_i.clamp(1, 100)
  
  # Construir consulta
  dataset = Profile.dataset
  dataset = dataset.where(Sequel.lit("nombre_completo ILIKE ? OR correo ILIKE ?", 
                                    "%#{query}%", "%#{query}%")) if query
  
  # Paginación
  total = dataset.count
  profiles = dataset.limit(per_page, (page - 1) * per_page).map(&:to_api)
  
  json_response(
    data: profiles,
    pagination: {
      current_page: page,
      per_page: per_page,
      total_pages: (total.to_f / per_page).ceil,
      total_count: total
    }
  )
end

# Manejo de errores
error do
  status 500
  { error: env['sinatra.error'].message }.to_json
end

unless DB.table_exists?(:profiles)
  DB.create_table :profiles do
    primary_key :id
    String :email, unique: true, null: false
    String :full_name
    String :avatar_url
    Jsonb  :preferences
    DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    DateTime :updated_at, default: Sequel::CURRENT_TIMESTAMP
  end
end

PROFILES = DB[:profiles]

get '/profiles/:id' do |id|
  profile = PROFILES.where(id: id).first
  halt 404, { error: 'No encontrado' }.to_json unless profile
  profile.to_json
end

post '/profiles' do
  email = authorized_email
  data = json_body
  begin
    id = PROFILES.insert(email: email, full_name: data['full_name'], avatar_url: data['avatar_url'], preferences: data['preferences'])
    status 201
    { id: id }.to_json
  rescue Sequel::UniqueConstraintViolation
    halt 409, { error: 'Perfil ya existe' }.to_json
  end
end

put '/profiles/:id' do |id|
  email = authorized_email
  data = json_body
  updated = PROFILES.where(id: id).update(full_name: data['full_name'], avatar_url: data['avatar_url'], preferences: data['preferences'])
  halt 404, { error: 'No encontrado' }.to_json if updated.zero?
  { updated: true }.to_json
end

patch '/profiles/:id' do |id|
  email = authorized_email
  data = json_body
  updated = PROFILES.where(id: id).update(data)
  halt 404, { error: 'No encontrado' }.to_json if updated.zero?
  { updated: true }.to_json
end

delete '/profiles/:id' do |id|
  email = authorized_email
  deleted = PROFILES.where(id: id).delete
  halt 404, { error: 'No encontrado' }.to_json if deleted.zero?
  { deleted: true }.to_json
end
