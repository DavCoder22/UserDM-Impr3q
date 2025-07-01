FactoryBot.define do
  factory :history_event, class: Hash do
    email { Faker::Internet.unique.email }
    event_type { %w[login logout profile_update password_change search purchase].sample }
    payload do
      case event_type
      when 'login'
        {
          ip_address: Faker::Internet.ip_v4_address,
          user_agent: Faker::Internet.user_agent,
          success: Faker::Boolean.boolean
        }
      when 'profile_update'
        {
          updated_fields: Faker::Hipster.words(number: 2),
          previous_values: { field: 'old_value' },
          new_values: { field: 'new_value' }
        }
      when 'purchase'
        {
          amount: Faker::Number.decimal(l_digits: 2),
          currency: 'USD',
          items: Array.new(rand(1..5)) { { id: Faker::Number.number(digits: 5), name: Faker::Commerce.product_name, quantity: rand(1..3) } }
        }
      else
        {}
      end
    end
    created_at { Time.now.utc.iso8601 }

    initialize_with { attributes }

    trait :with_timestamp do |t|
      created_at { t }
    end
  end
end
