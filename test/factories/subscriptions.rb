FactoryBot.define do
  factory :subscription do
    user
    stripe_subscription_id { "sub_#{SecureRandom.hex(12)}" }
    stripe_price_id { "price_#{SecureRandom.hex(12)}" }
    status { :active }
    current_period_start { Time.current }
    current_period_end { 1.month.from_now }

    trait :canceled do
      status { :canceled }
      canceled_at { Time.current }
    end

    trait :past_due do
      status { :past_due }
    end
  end
end
