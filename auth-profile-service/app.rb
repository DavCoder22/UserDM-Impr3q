require 'sinatra/base'
require 'json'
require_relative '../../lib/auth_helper'
require_relative '../../lib/database'

class AuthProfileService < Sinatra::Base
  configure do
    set :show_exceptions, false
  end

  before do
    content_type :json
    authenticate_request
  end

  helpers do
    def current_user
      @current_user ||= begin
        # El user_id ya debería estar en el entorno gracias a AuthHelper.authenticate_request
        user_id = request.env['user_id']
        
        result = Database::Connection.query(
          'SELECT * FROM users WHERE id = $1', [user_id]
        )
        result.first
      end
    end

    def authenticate_request
      begin
        AuthHelper.authenticate_request(request.env)
      rescue AuthHelper::AuthenticationError => e
        status 401
        return { error: 'Authentication failed', details: e.message }.to_json
      end
      
      # Verificar que el usuario existe en la base de datos
      unless current_user
        status 401
        return { error: 'User not found' }.to_json
      end
    end
  end

  # Get current user profile
  get '/' do
    user_data = {
      id: current_user['id'],
      nombre: current_user['nombre'],
      email: current_user['email'],
      rol: current_user['rol'],
      telefono: current_user['telefono'],
      ubicacion: current_user['ubicacion'] ? JSON.parse(current_user['ubicacion']) : nil,
      fecha_registro: current_user['fecha_registro']
    }

    if current_user['rol'] == 'impresor'
      user_data.merge!({
        impresoras: current_user['impresoras'],
        materiales: current_user['materiales'],
        tiempo_experiencia: current_user['tiempo_experiencia'],
        calificacion: current_user['calificacion']
      })
    else
      user_data[:historial_cotizaciones] = current_user['historial_cotizaciones'] || []
    end

    user_data.to_json
  end

  # Update profile
  put '/' do
    request.body.rewind
    data = JSON.parse(request.body.read, symbolize_names: true)

    allowed_fields = [:nombre, :telefono, :ubicacion]
    
    # Add role-specific fields
    if current_user['rol'] == 'impresor'
      allowed_fields += [:impresoras, :materiales, :tiempo_experiencia, :calificacion]
    end

    updates = data.select { |k, _| allowed_fields.include?(k) }

    if updates.empty?
      status 400
      return { error: 'No valid fields provided for update' }.to_json
    end

    # Convert arrays to PostgreSQL arrays
    updates.each do |k, v|
      if v.is_a?(Array)
        updates[k] = "{#{v.join(',')}}"
      elsif v.is_a?(Hash) || v.is_a?(Array)
        updates[k] = v.to_json
      end
    end

    set_clause = updates.keys.map.with_index(1) { |k, i| "#{k} = $#{i}" }.join(', ')
    values = updates.values
    values << current_user['id']

    begin
      Database::Connection.query(
        "UPDATE users SET #{set_clause} WHERE id = $#{values.length} RETURNING *",
        values
      )
      
      status 200
      { message: 'Profile updated successfully' }.to_json
    rescue PG::Error => e
      status 500
      { error: "Failed to update profile: #{e.message}" }.to_json
    end
  end

  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
