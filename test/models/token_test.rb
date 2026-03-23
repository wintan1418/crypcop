require "test_helper"

class TokenTest < ActiveSupport::TestCase
  test "valid token" do
    token = build(:token)
    assert token.valid?
  end

  test "requires mint_address" do
    token = build(:token, mint_address: nil)
    assert_not token.valid?
  end

  test "requires unique mint_address" do
    create(:token, mint_address: "abc123")
    token = build(:token, mint_address: "abc123")
    assert_not token.valid?
  end

  test "risk_level enum" do
    token = build(:token, risk_level: :critical)
    assert token.critical?
    assert_not token.safe?
  end

  test "recent scope orders by created_at desc" do
    old = create(:token, created_at: 2.days.ago)
    new_token = create(:token, created_at: 1.hour.ago)
    assert_equal new_token, Token.recent.first
  end

  test "scanned scope" do
    scanned = create(:token, last_scanned_at: Time.current)
    unscanned = create(:token, :unscanned)
    assert_includes Token.scanned, scanned
    assert_not_includes Token.scanned, unscanned
  end

  test "by_risk scope" do
    safe = create(:token, :safe)
    high = create(:token, :high_risk)
    assert_includes Token.by_risk(:safe), safe
    assert_not_includes Token.by_risk(:safe), high
  end

  test "trust_count and distrust_count" do
    token = create(:token)
    create(:trust_vote, token: token, vote: :trust)
    create(:trust_vote, token: token, vote: :trust)
    create(:trust_vote, token: token, vote: :distrust)
    assert_equal 2, token.trust_count
    assert_equal 1, token.distrust_count
  end

  test "trust_ratio" do
    token = create(:token)
    create(:trust_vote, token: token, vote: :trust)
    create(:trust_vote, token: token, vote: :distrust)
    assert_equal 50, token.trust_ratio
  end

  test "trust_ratio with no votes" do
    token = create(:token)
    assert_equal 0, token.trust_ratio
  end

  test "age_text" do
    token = build(:token, created_on_chain_at: 30.minutes.ago)
    assert_match(/\d+m ago/, token.age_text)
  end

  test "risk_color" do
    assert_equal "text-green-400", build(:token, risk_level: :safe).risk_color
    assert_equal "text-red-500", build(:token, risk_level: :high).risk_color
  end
end
