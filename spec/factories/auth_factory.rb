FactoryBot.define do
  factory :user, class: Hash do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }

    initialize_with { attributes }
  end

  factory :login_credentials, class: Hash do
    email { Faker::Internet.email }
    password { 'password123' }

    initialize_with { attributes }
  end
end
