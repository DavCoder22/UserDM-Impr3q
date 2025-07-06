# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { 'password' }
    password_confirmation { 'password' }
    nombre { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    telefono { Faker::PhoneNumber.phone_number }
    direccion { Faker::Address.full_address }
    rol { %w[cliente administrador].sample }
    activo { true }
    confirmed_at { Time.current }
    
    trait :admin do
      rol { 'administrador' }
    end
    
    trait :cliente do
      rol { 'cliente' }
    end
    
    trait :inactive do
      activo { false }
    end
    
    trait :unconfirmed do
      confirmed_at { nil }
    end
    
    trait :with_reset_password_token do
      reset_password_token { SecureRandom.urlsafe_base64 }
      reset_password_sent_at { Time.current }
    end
    
    trait :with_unlock_token do
      unlock_token { SecureRandom.urlsafe_base64 }
      locked_at { 1.hour.ago }
    end
    
    trait :with_confirmation_token do
      confirmation_token { SecureRandom.urlsafe_base64 }
      confirmation_sent_at { Time.current }
    end
    
    trait :with_all_tokens do
      with_reset_password_token
      with_unlock_token
      with_confirmation_token
    end
  end
end
