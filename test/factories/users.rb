FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    password_confirmation { "password123" }
    tier { :free }
    daily_scan_count { 0 }

    trait :pro do
      tier { :pro }
    end

    trait :scan_limit_reached do
      daily_scan_count { 10 }
      daily_scan_reset_at { Time.current }
    end
  end
end
