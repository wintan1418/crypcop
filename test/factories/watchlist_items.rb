FactoryBot.define do
  factory :watchlist_item do
    user
    token
    notify_on_risk_change { true }
    notify_on_price_change { false }
  end
end
