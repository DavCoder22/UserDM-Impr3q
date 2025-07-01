FactoryBot.define do
  factory :profile do
    user_id { Faker::Number.unique.number(digits: 5) }
    nombre_completo { Faker::Name.name }
    correo { Faker::Internet.unique.email }
    telefono { Faker::PhoneNumber.phone_number }
    direccion { Faker::Address.full_address }
    fecha_nacimiento { Faker::Date.birthday(min_age: 18, max_age: 65) }
    genero { ['M', 'F', 'O'].sample }
    avatar_url { Faker::Internet.url(path: '/avatar.jpg') }
    created_at { Time.now }
    updated_at { Time.now }

    trait :with_user do
      after(:build) do |profile, evaluator|
        user_id = evaluator.user_id || create(:user).id
        profile.user_id = user_id
      end
    end
  end

  factory :user do
    id { Faker::Number.unique.number(digits: 5) }
    nombre { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    correo { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    rol { 'user' }
    activo { true }
    created_at { Time.now }
    updated_at { Time.now }

    trait :admin do
      rol { 'admin' }
    end
  end
end
