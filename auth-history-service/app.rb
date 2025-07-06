require 'sinatra/base'
require 'json'
require_relative '../../lib/auth_helper'
require_relative '../../lib/database'

class AuthHistoryService < Sinatra::Base
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
          'SELECT id, rol FROM users WHERE id = $1', [user_id]
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

  # Get login history for the current user
  get '/' do
    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min # Cap at 100 per page
    offset = (page - 1) * per_page

    # Get total count
    count_result = Database::Connection.query(
      'SELECT COUNT(*) FROM login_history WHERE user_id = $1',
      [current_user['id']]
    )
    total = count_result.first['count'].to_i

    # Get paginated results
    result = Database::Connection.query(
      'SELECT id, login_time, ip_address, user_agent '
      'FROM login_history '
      'WHERE user_id = $1 '
      'ORDER BY login_time DESC '
      'LIMIT $2 OFFSET $3',
      [current_user['id'], per_page, offset]
    )

    history = result.map do |row|
      {
        id: row['id'],
        login_time: row['login_time'],
        ip_address: row['ip_address'],
        user_agent: row['user_agent']
      }
    end

    {
      data: history,
      pagination: {
        page: page,
        per_page: per_page,
        total_entries: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }.to_json
  end

  # Admin endpoint to get login history for any user (requires admin role)
  get '/:user_id' do
    # Only allow admins to view other users' history
    unless current_user['rol'] == 'admin'
      status 403
      return { error: 'Forbidden' }.to_json
    end

    user_id = params[:user_id]
    
    # Verify user exists
    user_result = Database::Connection.query(
      'SELECT id FROM users WHERE id = $1', [user_id]
    )
    
    unless user_result.any?
      status 404
      return { error: 'User not found' }.to_json
    end

    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, 100].min
    offset = (page - 1) * per_page

    # Get total count
    count_result = Database::Connection.query(
      'SELECT COUNT(*) FROM login_history WHERE user_id = $1',
      [user_id]
    )
    total = count_result.first['count'].to_i

    # Get paginated results
    result = Database::Connection.query(
      'SELECT id, login_time, ip_address, user_agent '
      'FROM login_history '
      'WHERE user_id = $1 '
      'ORDER BY login_time DESC '
      'LIMIT $2 OFFSET $3',
      [user_id, per_page, offset]
    )

    history = result.map do |row|
      {
        id: row['id'],
        login_time: row['login_time'],
        ip_address: row['ip_address'],
        user_agent: row['user_agent']
      }
    end

    {
      data: history,
      pagination: {
        page: page,
        per_page: per_page,
        total_entries: total,
        total_pages: (total.to_f / per_page).ceil
      }
    }.to_json
  end

  error do |err|
    status 500
    { error: "Internal server error: #{err.message}" }.to_json
  end
end
