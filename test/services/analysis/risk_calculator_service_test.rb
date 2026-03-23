require "test_helper"

class Analysis::RiskCalculatorServiceTest < ActiveSupport::TestCase
  test "safe token scores low" do
    token = build(:token, :safe,
      mint_authority_revoked: true,
      freeze_authority_revoked: true,
      top_10_holder_pct: 15.0,
      liquidity_usd: 50000,
      lp_locked: true,
      is_mutable: false,
      holder_count: 500,
      created_on_chain_at: 2.days.ago
    )

    result = Analysis::RiskCalculatorService.new(token).calculate
    assert result[:risk_score] <= 20
    assert_equal :safe, result[:risk_level]
    assert result[:flags].empty?
  end

  test "risky token scores high" do
    token = build(:token, :high_risk,
      mint_authority_revoked: false,
      freeze_authority_revoked: false,
      top_10_holder_pct: 75.0,
      liquidity_usd: 2000,
      lp_locked: false,
      is_mutable: true,
      holder_count: 5,
      created_on_chain_at: 30.minutes.ago
    )

    result = Analysis::RiskCalculatorService.new(token).calculate
    assert result[:risk_score] >= 80
    assert_includes [ :high, :critical ], result[:risk_level]
    assert result[:flags].size >= 5
  end

  test "mint authority not revoked adds 30 points" do
    base_attrs = {
      mint_authority_revoked: true, freeze_authority_revoked: true,
      top_10_holder_pct: 15.0, liquidity_usd: 50000, lp_locked: true,
      is_mutable: false, holder_count: 500, created_on_chain_at: 2.days.ago
    }
    safe = build(:token, **base_attrs)
    risky = build(:token, **base_attrs.merge(mint_authority_revoked: false))

    safe_result = Analysis::RiskCalculatorService.new(safe).calculate
    risky_result = Analysis::RiskCalculatorService.new(risky).calculate

    assert_equal 30, risky_result[:risk_score] - safe_result[:risk_score]
  end

  test "generates summary based on risk level" do
    safe_token = build(:token, :safe, mint_authority_revoked: true, freeze_authority_revoked: true,
      lp_locked: true, is_mutable: false, holder_count: 100, created_on_chain_at: 2.days.ago,
      top_10_holder_pct: 10.0, liquidity_usd: 50000)
    result = Analysis::RiskCalculatorService.new(safe_token).calculate
    assert_includes result[:summary], "low risk"
  end

  test "flags describe specific issues" do
    token = build(:token, mint_authority_revoked: false, lp_locked: false)
    result = Analysis::RiskCalculatorService.new(token).calculate

    flag_texts = result[:flags].join(" ")
    assert_includes flag_texts, "Mint authority"
    assert_includes flag_texts, "Liquidity pool"
  end

  test "score capped at 100" do
    token = build(:token,
      mint_authority_revoked: false,
      freeze_authority_revoked: false,
      top_10_holder_pct: 90.0,
      liquidity_usd: 100,
      lp_locked: false,
      is_mutable: true,
      holder_count: 2,
      created_on_chain_at: 5.minutes.ago
    )

    result = Analysis::RiskCalculatorService.new(token).calculate
    assert result[:risk_score] <= 100
  end
end
