FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_hash { BCrypt::Password.create('password123') }
    nombre { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    telefono { Faker::PhoneNumber.phone_number }
    rol { %w[cliente impresor admin].sample }
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
  end
  
  factory :login_history do
    user_id { create(:user).id }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    success { true }
    reason { nil }
    created_at { Time.now.utc }
  end
end
