FactoryBot.define do
  factory :scan do
    token
    user { nil }
    risk_score { 25 }
    risk_level { :low }
    ai_summary { "This token shows moderate risk. Mint authority is revoked but liquidity is relatively low." }
    ai_analysis { { sections: { overview: "Moderate risk token" } } }
    flags { [ "Low liquidity", "New token" ] }
    scan_type { :auto }
    status { :completed }
    completed_at { Time.current }

    trait :pending do
      status { :pending }
      risk_score { 0 }
      risk_level { :safe }
      ai_summary { nil }
      completed_at { nil }
    end

    trait :failed do
      status { :failed }
      error_message { "API rate limit exceeded" }
      completed_at { nil }
    end

    trait :manual do
      scan_type { :manual }
      association :user
    end
  end
end
