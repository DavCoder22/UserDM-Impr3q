require 'sinatra/base'
require 'json'
require_relative '../../lib/jwt_auth'
require_relative '../models/user'
require_relative '../models/session'

class AuthController < Sinatra::Base
  configure do
    set :show_exceptions, :after_handler
    set :db, nil  # Se configurará al inicializar la aplicación
    set :redis, nil  # Se configurará al inicializar la aplicación
  end

  before do
    content_type :json
  end

  # Endpoint de registro
  post '/register' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    
    # Validar campos requeridos
    required_fields = [:email, :password, :nombre, :telefono, :rol]
    missing_fields = required_fields.reject { |field| data.key?(field) }
    
    if missing_fields.any?
      status 400
      return { error: "Faltan campos requeridos: #{missing_fields.join(', ')}" }.to_json
    end
    
    # Validar rol
    unless %w[cliente impresor].include?(data[:rol])
      status 400
      return { error: "Rol inválido. Debe ser 'cliente' o 'impresor'" }.to_json
    end
    
    # Verificar si el usuario ya existe
    if User.find_by_email(settings.db, data[:email])
      status 409
      return { error: 'Ya existe un usuario con este correo electrónico' }.to_json
    end
    
    # Crear usuario
    user = User.new(
      email: data[:email],
      nombre: data[:nombre],
      apellido: data[:apellido],
      telefono: data[:telefono],
      rol: data[:rol]
    )
    user.password = data[:password]
    
    # Guardar usuario
    user.save(settings.db)
    
    # Crear sesión
    session = create_session(user, request)
    
    # Generar tokens
    access_token = JWTAuth.generate_access_token(user.id, user.rol, session.id)
    refresh_token = JWTAuth.generate_refresh_token(user.id, session.id)
    
    # Actualizar sesión con tokens
    session.token = access_token
    session.refresh_token = refresh_token
    session.save(settings.db)
    
    # Enviar respuesta
    status 201
    {
      message: 'Usuario registrado exitosamente',
      user: {
        id: user.id,
        email: user.email,
        nombre: user.nombre,
        rol: user.rol
      },
      tokens: {
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: ENV.fetch('JWT_ACCESS_TOKEN_EXP', 3600).to_i
      }
    }.to_json
  end
  
  # Endpoint de inicio de sesión
  post '/login' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    
    # Validar campos requeridos
    unless data[:email] && data[:password]
      status 400
      return { error: 'Se requieren email y contraseña' }.to_json
    end
    
    # Autenticar usuario
    user = User.authenticate(settings.db, data[:email], data[:password])
    
    unless user
      status 401
      return { error: 'Email o contraseña incorrectos' }.to_json
    end
    
    # Crear sesión
    session = create_session(user, request)
    
    # Generar tokens
    access_token = JWTAuth.generate_access_token(user.id, user.rol, session.id)
    refresh_token = JWTAuth.generate_refresh_token(user.id, session.id)
    
    # Actualizar sesión con tokens
    session.token = access_token
    session.refresh_token = refresh_token
    session.save(settings.db)
    
    # Registrar inicio de sesión exitoso
    log_login_attempt(user.id, request, true)
    
    # Enviar respuesta
    {
      message: 'Inicio de sesión exitoso',
      user: {
        id: user.id,
        email: user.email,
        nombre: user.nombre,
        rol: user.rol
      },
      tokens: {
        access_token: access_token,
        refresh_token: refresh_token,
        expires_in: ENV.fetch('JWT_ACCESS_TOKEN_EXP', 3600).to_i
      }
    }.to_json
  end
  
  # Endpoint de cierre de sesión
  post '/logout' do
    auth_header = request.env['HTTP_AUTHORIZATION']
    
    unless auth_header && auth_header.start_with?('Bearer ')
      status 401
      return { error: 'Token de autenticación no proporcionado' }.to_json
    end
    
    token = auth_header.split(' ').last
    
    begin
      # Invalidar token actual
      JWTAuth.invalidate_token(token, settings.redis)
      
      # Obtener datos del token para actualizar la sesión
      payload = JWTAuth.decode_token(token)
      
      if payload[:session_id]
        session = Session.find_by_id(settings.db, payload[:session_id])
        if session
          session.revoke!
          session.save(settings.db)
        end
      end
      
      { message: 'Sesión cerrada exitosamente' }.to_json
    rescue => e
      status 500
      { error: 'Error al cerrar la sesión' }.to_json
    end
  end
  
  # Endpoint para refrescar token
  post '/refresh-token' do
    refresh_token = request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
    
    unless refresh_token
      status 401
      return { error: 'Token de refresco no proporcionado' }.to_json
    end
    
    begin
      # Verificar token de refresco
      payload = JWTAuth.decode_token(refresh_token)
      
      if payload[:error]
        status 401
        return { error: payload[:error] }.to_json
      end
      
      unless payload[:type] == 'refresh' && payload[:session_id]
        status 401
        return { error: 'Token de refresco inválido' }.to_json
      end
      
      # Verificar si la sesión existe y está activa
      session = Session.find_by_id(settings.db, payload[:session_id])
      
      unless session && session.active? && session.refresh_token == refresh_token
        status 401
        return { error: 'Sesión no válida o expirada' }.to_json
      end
      
      # Obtener usuario
      user = User.find_by_id(settings.db, payload[:user_id])
      
      unless user && user.cuenta_activa?
        status 401
        return { error: 'Usuario no encontrado o inactivo' }.to_json
      end
      
      # Generar nuevos tokens
      new_access_token = JWTAuth.generate_access_token(user.id, user.rol, session.id)
      new_refresh_token = JWTAuth.generate_refresh_token(user.id, session.id)
      
      # Actualizar sesión
      session.token = new_access_token
      session.refresh_token = new_refresh_token
      session.update_activity!
      session.save(settings.db)
      
      # Enviar respuesta
      {
        access_token: new_access_token,
        refresh_token: new_refresh_token,
        expires_in: ENV.fetch('JWT_ACCESS_TOKEN_EXP', 3600).to_i
      }.to_json
      
    rescue JWT::DecodeError => e
      status 401
      { error: 'Token inválido' }.to_json
    rescue => e
      status 500
      { error: 'Error al refrescar el token' }.to_json
    end
  end
  
  # Endpoint para verificar token
  get '/verify-token' do
    auth_header = request.env['HTTP_AUTHORIZATION']
    
    unless auth_header && auth_header.start_with?('Bearer ')
      status 401
      return { error: 'Token no proporcionado' }.to_json
    end
    
    token = auth_header.split(' ').last
    
    begin
      payload = JWTAuth.decode_token(token)
      
      if payload[:error]
        status 401
        return { error: payload[:error] }.to_json
      end
      
      unless JWTAuth.valid_token?(token, settings.redis)
        status 401
        return { error: 'Token revocado o inválido' }.to_json
      end
      
      # Verificar si el usuario existe y está activo
      user = User.find_by_id(settings.db, payload[:user_id])
      
      unless user && user.cuenta_activa?
        status 401
        return { error: 'Usuario no encontrado o inactivo' }.to_json
      end
      
      # Verificar la sesión si está disponible
      if payload[:session_id]
        session = Session.find_by_id(settings.db, payload[:session_id])
        
        unless session && session.active? && session.token == token
          status 401
          return { error: 'Sesión no válida o expirada' }.to_json
        end
        
        # Actualizar última actividad
        session.update_activity!
        session.save(settings.db)
      end
      
      # Token válido
      {
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          nombre: user.nombre,
          rol: user.rol
        },
        expires_at: payload[:exp]
      }.to_json
      
    rescue JWT::DecodeError => e
      status 401
      { error: 'Token inválido' }.to_json
    rescue => e
      status 500
      { error: 'Error al verificar el token' }.to_json
    end
  end
  
  # Endpoint para recuperar contraseña
  post '/forgot-password' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    
    unless data[:email]
      status 400
      return { error: 'Se requiere el correo electrónico' }.to_json
    end
    
    user = User.find_by_email(settings.db, data[:email])
    
    # Por seguridad, no revelamos si el correo existe o no
    if user
      # En un entorno real, aquí enviaríamos un correo con el enlace de restablecimiento
      token = user.generate_password_reset_token(settings.db)
      reset_url = "#{ENV['APP_URL']}/reset-password?token=#{token}"
      
      # En producción, implementar el envío de correo aquí
      puts "Enlace de restablecimiento: #{reset_url}"
    end
    
    { message: 'Si el correo existe, se ha enviado un enlace para restablecer la contraseña' }.to_json
  end
  
  # Endpoint para restablecer contraseña
  post '/reset-password' do
    data = JSON.parse(request.body.read, symbolize_names: true)
    
    required_fields = [:token, :new_password]
    missing_fields = required_fields.reject { |field| data.key?(field) }
    
    if missing_fields.any?
      status 400
      return { error: "Faltan campos requeridos: #{missing_fields.join(', ')}" }.to_json
    end
    
    # Buscar usuario por token de restablecimiento
    result = settings.db.exec_params(
      'SELECT * FROM users WHERE reset_password_token = $1 AND reset_token_expires > NOW()',
      [data[:token]]
    ).first
    
    unless result
      status 400
      return { error: 'Token de restablecimiento inválido o expirado' }.to_json
    end
    
    user = User.new_from_result(result)
    
    # Actualizar contraseña
    user.password = data[:new_password]
    user.reset_password_token = nil
    user.reset_token_expires = nil
    
    if user.save(settings.db)
      # Invalidar todas las sesiones del usuario
      settings.db.exec_params(
        'UPDATE sessions SET revoked_at = NOW() WHERE user_id = $1',
        [user.id]
      )
      
      { message: 'Contraseña actualizada exitosamente' }.to_json
    else
      status 500
      { error: 'Error al actualizar la contraseña' }.to_json
    end
  end
  
  private
  
  def create_session(user, request)
    # Obtener información del dispositivo
    user_agent = request.user_agent || 'Desconocido'
    ip_address = request.ip
    
    # Crear nueva sesión
    session = Session.new(
      user_id: user.id,
      ip_address: ip_address,
      user_agent: user_agent,
      device_info: {
        browser: request.env['HTTP_USER_AGENT'],
        platform: request.user_agent
      }
    )
    
    session.save(settings.db)
    session
  end
  
  def log_login_attempt(user_id, request, success, reason = nil)
    settings.db.exec_params(
      'INSERT INTO login_history (user_id, ip_address, user_agent, success, reason, created_at) ' \
      'VALUES ($1, $2, $3, $4, $5, NOW())',
      [user_id, request.ip, request.user_agent, success, reason]
    )
  end
  
  # Manejador de errores
  error do
    status 500
    { error: 'Error interno del servidor' }.to_json
  end
end
