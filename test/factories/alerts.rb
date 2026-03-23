FactoryBot.define do
  factory :alert do
    user
    token
    alert_type { :risk_increase }
    title { "Risk increased for #{Faker::CryptoCoin.coin_name}" }
    message { "Risk score changed from 20 to 65. Multiple red flags detected." }

    trait :read do
      read_at { Time.current }
    end

    trait :emailed do
      emailed_at { Time.current }
    end
  end
end
