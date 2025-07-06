# frozen_string_literal: true

FactoryBot.define do
  factory :session do
    association :user
    token { SecureRandom.hex(32) }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
    expires_at { 30.days.from_now }
    
    trait :expired do
      expires_at { 1.day.ago }
    end
    
    trait :with_long_expiration do
      expires_at { 1.year.from_now }
    end
    
    trait :with_short_expiration do
      expires_at { 1.hour.from_now }
    end
    
    trait :mobile do
      user_agent { 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15' }
    end
    
    trait :desktop do
      user_agent { 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36' }
    end
    
    trait :tablet do
      user_agent { 'Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) AppleWebKit/605.1.15' }
    end
    
    trait :with_metadata do
      metadata do
        {
          browser: Faker::Internet.user_agent,
          platform: %w[windows macos linux ios android].sample,
          location: Faker::Address.country,
          device_id: SecureRandom.hex(16)
        }
      end
    end
    
    trait :with_remember_me do
      remember_me { true }
      expires_at { 1.year.from_now }
    end
    
    trait :without_remember_me do
      remember_me { false }
      expires_at { 30.minutes.from_now }
    end
    
    factory :admin_session do
      association :user, :admin
    end
    
    factory :expired_session, traits: [:expired]
    factory :mobile_session, traits: [:mobile]
    factory :desktop_session, traits: [:desktop]
    factory :tablet_session, traits: [:tablet]
    
    after(:build) do |session|
      # Asegurarse de que el token esté encriptado si es necesario
      session.token ||= Session.generate_token
    end
  end
end
