FactoryBot.define do
  factory :profile, class: Hash do
    email { Faker::Internet.unique.email }
    nombre { Faker::Name.first_name }
    apellido { Faker::Name.last_name }
    telefono { Faker::PhoneNumber.phone_number }
    direccion { Faker::Address.full_address }
    fecha_nacimiento { Faker::Date.birthday(min_age: 18, max_age: 90).strftime('%Y-%m-%d') }
    genero { %w[masculino femenino otro preferiria_no_decirlo].sample }
    
    initialize_with { attributes }
    
    trait :with_avatar do
      avatar_url { Faker::Avatar.image }
    end
    
    trait :with_metadata do
      metadata do
        {
          preferencias: {
            tema: %w[claro oscuro sistema].sample,
            notificaciones: Faker::Boolean.boolean,
            idioma: %w[es en fr].sample
          },
          ultimo_acceso: Time.now.utc.iso8601,
          dispositivo: {
            tipo: %w[movil escritorio tablet].sample,
            navegador: %w[chrome firefox safari edge].sample,
            os: %w[windows macos linux ios android].sample
          }
        }
      end
    end
  end
end
