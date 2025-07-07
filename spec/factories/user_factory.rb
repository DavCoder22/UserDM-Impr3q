FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_hash { BCrypt::Password.create('password123') }
    nombre { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    telefono { Faker::PhoneNumber.phone_number }
    rol { 'cliente' }
    email_verificado { true }
    cuenta_activa { true }
    fecha_registro { Time.now.utc }
    
    trait :cliente do
      rol { 'cliente' }
    end
    
    trait :impresor do
      rol { 'impresor' }
    end
    
    trait :admin do
      rol { 'admin' }
    end
    
    trait :inactive do
      cuenta_activa { false }
    end
    
    trait :unverified do
      email_verificado { false }
    end
    
    # Método para crear usuario en la base de datos
    after(:build) do |user, evaluator|
      # Asegurar que el password_hash esté configurado
      if evaluator.password && !evaluator.password_hash
        user.password_hash = BCrypt::Password.create(evaluator.password)
      end
    end
    
    # Método para guardar en base de datos si está disponible
    after(:create) do |user, evaluator|
      if $db_connection
        user.save($db_connection)
      end
    end
  end
  
  factory :session do
    user_id { create(:user).id }
    token { "token_#{SecureRandom.hex(16)}" }
    refresh_token { "refresh_#{SecureRandom.hex(16)}" }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    device_info { { browser: 'Chrome', os: 'Windows 10' }.to_json }
    created_at { Time.now.utc }
    updated_at { Time.now.utc }
    expires_at { 30.days.from_now.utc }
    last_activity_at { Time.now.utc }
    
    trait :expired do
      expires_at { 1.day.ago.utc }
    end
    
    trait :revoked do
      revoked_at { 1.hour.ago.utc }
    end
    
    # Método para guardar en base de datos si está disponible
    after(:create) do |session, evaluator|
      if $db_connection
        session.save($db_connection)
      end
    end
  end
  
  factory :login_history do
    user_id { create(:user).id }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    success { true }
    reason { nil }
    created_at { Time.now.utc }
    
    # Método para guardar en base de datos si está disponible
    after(:create) do |history, evaluator|
      if $db_connection
        # Insertar directamente en la base de datos
        $db_connection.exec_params(
          'INSERT INTO login_history (user_id, ip_address, user_agent, success, reason, created_at) VALUES ($1, $2, $3, $4, $5, $6)',
          [
            history.user_id,
            history.ip_address,
            history.user_agent,
            history.success,
            history.reason,
            history.created_at
          ]
        )
      end
    end
  end
end
