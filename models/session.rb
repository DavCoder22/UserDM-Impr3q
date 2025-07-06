require 'securerandom'

class Session
  attr_reader :id, :user_id, :token, :refresh_token, :ip_address, :user_agent, :device_info,
              :created_at, :updated_at, :expires_at, :revoked_at, :last_activity_at

  def initialize(attributes = {})
    @id = attributes[:id] || SecureRandom.uuid
    @user_id = attributes[:user_id]
    @token = attributes[:token]
    @refresh_token = attributes[:refresh_token]
    @ip_address = attributes[:ip_address]
    @user_agent = attributes[:user_agent]
    @device_info = attributes[:device_info] || {}
    @created_at = attributes[:created_at] || Time.now.utc
    @updated_at = attributes[:updated_at] || Time.now.utc
    @expires_at = attributes[:expires_at] || (Time.now.utc + 30.days)
    @revoked_at = attributes[:revoked_at]
    @last_activity_at = attributes[:last_activity_at] || Time.now.utc
  end

  def active?
    !revoked? && !expired?
  end

  def revoked?
    !@revoked_at.nil?
  end

  def expired?
    @expires_at < Time.now.utc
  end

  def revoke!
    @revoked_at = Time.now.utc
    @updated_at = Time.now.utc
  end

  def update_activity!
    @last_activity_at = Time.now.utc
    @updated_at = Time.now.utc
  end

  # Métodos para persistencia
  def save(db_conn)
    if exists?(db_conn)
      update(db_conn)
    else
      insert(db_conn)
    end
  end

  def self.find_by_id(db_conn, session_id)
    result = db_conn.exec_params(
      'SELECT * FROM sessions WHERE id = $1', [session_id]
    ).first
    
    return nil unless result
    new_from_result(result)
  end

  def self.find_by_token(db_conn, token)
    result = db_conn.exec_params(
      'SELECT * FROM sessions WHERE token = $1', [token]
    ).first
    
    return nil unless result
    new_from_result(result)
  end

  def self.find_active_by_user(db_conn, user_id)
    results = db_conn.exec_params(
      'SELECT * FROM sessions WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()', 
      [user_id]
    )
    
    results.map { |r| new_from_result(r) }
  end

  private

  def self.new_from_result(result)
    new(
      id: result['id'],
      user_id: result['user_id'],
      token: result['token'],
      refresh_token: result['refresh_token'],
      ip_address: result['ip_address'],
      user_agent: result['user_agent'],
      device_info: result['device_info'] ? JSON.parse(result['device_info']) : {},
      created_at: result['created_at'] ? Time.parse(result['created_at']).utc : nil,
      updated_at: result['updated_at'] ? Time.parse(result['updated_at']).utc : nil,
      expires_at: result['expires_at'] ? Time.parse(result['expires_at']).utc : nil,
      revoked_at: result['revoked_at'] ? Time.parse(result['revoked_at']).utc : nil,
      last_activity_at: result['last_activity_at'] ? Time.parse(result['last_activity_at']).utc : nil
    )
  end

  def exists?(db_conn)
    result = db_conn.exec_params(
      'SELECT 1 FROM sessions WHERE id = $1', [@id]
    )
    
    !result.values.empty?
  end

  def insert(db_conn)
    db_conn.exec_params(
      'INSERT INTO sessions (id, user_id, token, refresh_token, ip_address, user_agent, ' \
      'device_info, created_at, updated_at, expires_at, revoked_at, last_activity_at) ' \
      'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)',
      [
        @id, @user_id, @token, @refresh_token, @ip_address, @user_agent,
        @device_info.to_json, @created_at, @updated_at, @expires_at, @revoked_at, @last_activity_at
      ]
    )
  end

  def update(db_conn)
    @updated_at = Time.now.utc
    
    db_conn.exec_params(
      'UPDATE sessions SET token = $1, refresh_token = $2, updated_at = $3, ' \
      'revoked_at = $4, last_activity_at = $5 WHERE id = $6',
      [@token, @refresh_token, @updated_at, @revoked_at, @last_activity_at, @id]
    )
  end
end
