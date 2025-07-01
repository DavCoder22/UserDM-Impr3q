require 'sinatra'
require 'jwt'
require 'bcrypt'
require 'json'
require 'dotenv/load'
require_relative 'config/database'

# Cargar modelos
require_relative 'models/user'
require_relative 'models/token'

# Configuración de la aplicación
set :bind, '0.0.0.0'
set :environment, ENV['RACK_ENV'] || 'development'

# Configurar CORS
configure do
  enable :sessions
  set :session_secret, ENV.fetch('SESSION_SECRET') { SecureRandom.hex(64) }
  set :protection, except: [:json_csrf]
end

# Configurar el logger
configure :development do
  require 'sinatra/reloader'
  also_reload 'models/*.rb'
  also_reload 'config/*.rb'
  
  use Rack::CommonLogger, $stdout
  $stdout.sync = true
end

# Middleware para manejo de errores
error do
  status 500
  { error: env['sinatra.error'].message }.to_json
end

# Helpers
helpers do
  def json_body
    request.body.rewind
    JSON.parse(request.body.read) rescue {}
  end
  
  def authenticate!
    auth_header = request.env['HTTP_AUTHORIZATION']
    token = auth_header&.gsub(/^Bearer /, '')
    
    @current_user = if token
      Token.find_by_jwt(token)&.user
    end
    
    halt 401, { error: 'No autorizado' }.to_json unless @current_user
  end
  
  def current_user
    @current_user ||= authenticate!
  end
  
  def admin_only!
    authenticate!
    halt 403, { error: 'Acceso denegado' }.to_json unless current_user.rol == 'admin'
  end
end

# Endpoint para obtener información del sistema
get '/' do
  {
    name: 'Auth Service',
    version: '1.0.0',
    status: 'running',
    environment: settings.environment.to_s
  }.to_json
end

# Endpoint de registro de usuarios
post '/register' do
  data = json_body
  
  # Validar datos de entrada
  required_fields = ['nombre', 'correo', 'password']
  missing_fields = required_fields.select { |field| data[field].to_s.empty? }
  
  unless missing_fields.empty?
    status 400
    return { error: "Faltan campos requeridos: #{missing_fields.join(', ')}" }.to_json
  end
  
  begin
    # Crear nuevo usuario
    user = User.new(
      nombre: data['nombre'],
      correo: data['correo'],
      password_hash: data['password'],
      rol: data['rol'] || 'usuario'
    )
    
    if user.valid? && user.save
      status 201
      { 
        message: 'Usuario registrado exitosamente',
        user: {
          id: user.id,
          nombre: user.nombre,
          correo: user.correo,
          rol: user.rol
        }
      }.to_json
    else
      status 422
      { error: 'Error al registrar el usuario', details: user.errors.full_messages }.to_json
    end
  rescue Sequel::UniqueConstraintViolation
    status 409
    { error: 'El correo electrónico ya está en uso' }.to_json
  rescue => e
    status 500
    { error: 'Error interno del servidor', details: e.message }.to_json
  end
end

# Endpoint de inicio de sesión
post '/login' do
  data = json_body
  
  # Validar datos de entrada
  unless data['correo'] && data['password']
    status 400
    return { error: 'Se requieren correo y contraseña' }.to_json
  end
  
  # Buscar usuario por correo
  user = User.where(correo: data['correo']).first
  
  # Verificar credenciales
  if user && BCrypt::Password.new(user.password_hash) == data['password']
    # Crear token JWT
    token = Token.create_for_user(user)
    
    {
      token: token.jwt,
      expires_in: (token.expira_en - Time.now).to_i,
      user: {
        id: user.id,
        nombre: user.nombre,
        correo: user.correo,
        rol: user.rol
      }
    }.to_json
  else
    status 401
    { error: 'Credenciales inválidas' }.to_json
  end
end

# Endpoint para cerrar sesión
delete '/logout' do
  authenticate!
  
  auth_header = request.env['HTTP_AUTHORIZATION']
  token_value = auth_header&.gsub(/^Bearer /, '')
  
  if token_value
    token = Token.find_by_jwt(token_value)
    token&.invalidate
    
    { message: 'Sesión cerrada exitosamente' }.to_json
  else
    status 400
    { error: 'Token no proporcionado' }.to_json
  end
end

# Endpoint para obtener el perfil del usuario actual
get '/me' do
  authenticate!
  
  {
    id: current_user.id,
    nombre: current_user.nombre,
    correo: current_user.correo,
    rol: current_user.rol,
    fecha_creacion: current_user.fecha_creacion
  }.to_json
end

# Endpoint para actualizar la contraseña
put '/change-password' do
  authenticate!
  data = json_body
  
  unless data['current_password'] && data['new_password']
    status 400
    return { error: 'Se requieren la contraseña actual y la nueva contraseña' }.to_json
  end
  
  # Verificar contraseña actual
  unless BCrypt::Password.new(current_user.password_hash) == data['current_password']
    status 401
    return { error: 'Contraseña actual incorrecta' }.to_json
  end
  
  # Actualizar contraseña
  begin
    current_user.update(password_hash: data['new_password'])
    
    # Invalidar todos los tokens del usuario (cerrar sesión en todos los dispositivos)
    current_user.invalidate_all_tokens
    
    { message: 'Contraseña actualizada exitosamente' }.to_json
  rescue => e
    status 500
    { error: 'Error al actualizar la contraseña', details: e.message }.to_json
  end
end

post '/register' do
  data = json_body
  email = data['email']
  password = data['password']
  halt 400, { error: 'Faltan datos' }.to_json unless email && password

  if USERS.key?(email)
    halt 409, { error: 'Usuario ya existe' }.to_json
  end

  USERS[email] = BCrypt::Password.create(password)
  status 201
end

post '/login' do
  data = json_body
  email = data['email']
  password = data['password']
  halt 400, { error: 'Faltan datos' }.to_json unless email && password

  stored = USERS[email]
  halt 401, { error: 'Credenciales inválidas' }.to_json unless stored && BCrypt::Password.new(stored) == password

  token = generate_token(email)
  { token: token }.to_json
end

get '/validate' do
  auth_header = request.env['HTTP_AUTHORIZATION']
  halt 401 unless auth_header&.start_with?('Bearer ')

  token = auth_header.split.last
  begin
    decoded = JWT.decode(token, JWT_SECRET, true, algorithm: 'HS256')
    { valid: true, payload: decoded.first }.to_json
  rescue JWT::DecodeError => e
    halt 401, { valid: false, error: e.message }.to_json
  end
end

after do
  content_type :json
end
