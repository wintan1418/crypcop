FactoryBot.define do
  factory :token do
    mint_address { Faker::Blockchain::Bitcoin.address }
    name { Faker::CryptoCoin.coin_name }
    symbol { Faker::CryptoCoin.acronym }
    decimals { 9 }
    supply { 1_000_000_000 }
    creator_address { Faker::Blockchain::Bitcoin.address }
    mint_authority_revoked { true }
    freeze_authority_revoked { true }
    is_mutable { false }
    created_on_chain_at { 2.hours.ago }
    latest_price_usd { rand(0.0001..100.0).round(8) }
    market_cap_usd { rand(1000..1_000_000).round(2) }
    liquidity_usd { rand(500..100_000).round(2) }
    holder_count { rand(10..5000) }
    top_10_holder_pct { rand(5.0..80.0).round(2) }
    lp_locked { true }
    risk_score { 15 }
    risk_level { :safe }
    last_scanned_at { 1.hour.ago }

    trait :unscanned do
      risk_score { nil }
      risk_level { :safe }
      last_scanned_at { nil }
    end

    trait :high_risk do
      risk_score { 85 }
      risk_level { :critical }
      mint_authority_revoked { false }
      freeze_authority_revoked { false }
      lp_locked { false }
      top_10_holder_pct { 75.0 }
    end

    trait :safe do
      risk_score { 10 }
      risk_level { :safe }
      mint_authority_revoked { true }
      freeze_authority_revoked { true }
      lp_locked { true }
      top_10_holder_pct { 15.0 }
    end
  end
end
