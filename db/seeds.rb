puts "Seeding CrypCop..."

# Create demo user
demo = User.find_or_create_by!(email: "demo@crypcop.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.tier = :free
end
puts "  Created demo user: demo@crypcop.com / password123"

# Create sample tokens
tokens_data = [
  {
    mint_address: "So11111111111111111111111111111111111111112",
    name: "Wrapped SOL", symbol: "SOL", decimals: 9,
    latest_price_usd: 145.32, market_cap_usd: 72_000_000_000,
    liquidity_usd: 500_000_000, volume_24h_usd: 2_000_000_000,
    holder_count: 5_000_000, top_10_holder_pct: 12.5,
    mint_authority_revoked: true, freeze_authority_revoked: true,
    lp_locked: true, is_mutable: false,
    risk_score: 5, risk_level: :safe,
    created_on_chain_at: 3.years.ago, last_scanned_at: 1.hour.ago
  },
  {
    mint_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v",
    name: "USD Coin", symbol: "USDC", decimals: 6,
    latest_price_usd: 1.0, market_cap_usd: 45_000_000_000,
    liquidity_usd: 1_000_000_000, volume_24h_usd: 5_000_000_000,
    holder_count: 3_000_000, top_10_holder_pct: 18.0,
    mint_authority_revoked: false, freeze_authority_revoked: false,
    lp_locked: true, is_mutable: false,
    risk_score: 30, risk_level: :low,
    created_on_chain_at: 2.years.ago, last_scanned_at: 30.minutes.ago
  },
  {
    mint_address: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263",
    name: "Bonk", symbol: "BONK", decimals: 5,
    latest_price_usd: 0.0000234, market_cap_usd: 1_500_000_000,
    liquidity_usd: 45_000_000, volume_24h_usd: 120_000_000,
    holder_count: 800_000, top_10_holder_pct: 22.0,
    mint_authority_revoked: true, freeze_authority_revoked: true,
    lp_locked: true, is_mutable: false,
    risk_score: 12, risk_level: :safe,
    created_on_chain_at: 1.year.ago, last_scanned_at: 2.hours.ago
  },
  {
    mint_address: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN",
    name: "Jupiter", symbol: "JUP", decimals: 6,
    latest_price_usd: 0.85, market_cap_usd: 1_100_000_000,
    liquidity_usd: 35_000_000, volume_24h_usd: 80_000_000,
    holder_count: 400_000, top_10_holder_pct: 28.0,
    mint_authority_revoked: true, freeze_authority_revoked: true,
    lp_locked: true, is_mutable: false,
    risk_score: 15, risk_level: :safe,
    created_on_chain_at: 6.months.ago, last_scanned_at: 1.hour.ago
  },
  {
    mint_address: "FakeRug111111111111111111111111111111111111",
    name: "MOONSHOT2024", symbol: "MOON",
    latest_price_usd: 0.000001, market_cap_usd: 5000,
    liquidity_usd: 800, volume_24h_usd: 200,
    holder_count: 8, top_10_holder_pct: 92.0,
    mint_authority_revoked: false, freeze_authority_revoked: false,
    lp_locked: false, is_mutable: true,
    risk_score: 95, risk_level: :critical,
    created_on_chain_at: 20.minutes.ago, last_scanned_at: 10.minutes.ago
  },
  {
    mint_address: "SuspToken22222222222222222222222222222222222",
    name: "ELONPUMP", symbol: "EPUMP",
    latest_price_usd: 0.00005, market_cap_usd: 25000,
    liquidity_usd: 3000, volume_24h_usd: 1500,
    holder_count: 35, top_10_holder_pct: 68.0,
    mint_authority_revoked: false, freeze_authority_revoked: true,
    lp_locked: false, is_mutable: true,
    risk_score: 72, risk_level: :high,
    created_on_chain_at: 2.hours.ago, last_scanned_at: 30.minutes.ago
  },
  {
    mint_address: "MedRisk333333333333333333333333333333333333",
    name: "CatCoin", symbol: "CAT",
    latest_price_usd: 0.002, market_cap_usd: 150000,
    liquidity_usd: 12000, volume_24h_usd: 8000,
    holder_count: 250, top_10_holder_pct: 45.0,
    mint_authority_revoked: true, freeze_authority_revoked: true,
    lp_locked: false, is_mutable: true,
    risk_score: 48, risk_level: :medium,
    created_on_chain_at: 5.hours.ago, last_scanned_at: 1.hour.ago
  }
]

tokens_data.each do |data|
  token = Token.find_or_create_by!(mint_address: data[:mint_address]) do |t|
    data.except(:mint_address).each { |k, v| t.send(:"#{k}=", v) }
  end

  # Create a scan for each token
  unless token.scans.any?
    token.scans.create!(
      risk_score: token.risk_score || 0,
      risk_level: token.risk_level || :safe,
      ai_summary: case token.risk_level&.to_s
      when "safe" then "This token shows low risk. Key security features are in place with revoked authorities and locked liquidity."
      when "low" then "Minor risk indicators detected. Mint authority is still active on this stablecoin but this is expected for USDC."
      when "medium" then "Moderate risk detected. LP is unlocked and metadata is mutable. Top holders own #{token.top_10_holder_pct}% of supply."
      when "high" then "HIGH RISK: Multiple red flags detected. Mint authority active, LP unlocked, high holder concentration at #{token.top_10_holder_pct}%."
      when "critical" then "CRITICAL: This token exhibits classic rug-pull patterns. Unrevoked mint/freeze authorities, 92% holder concentration, $800 liquidity. Strongly avoid."
      else "Analysis pending."
      end,
      flags: token.risk_score.to_i > 50 ? [ "Mint authority active", "LP not locked", "High holder concentration" ] : [],
      scan_type: :auto,
      status: :completed,
      completed_at: token.last_scanned_at || Time.current
    )
  end
end

puts "  Created #{Token.count} tokens with scans"

# Add some tokens to demo user watchlist
[ "So11111111111111111111111111111111111111112", "FakeRug111111111111111111111111111111111111" ].each do |addr|
  token = Token.find_by(mint_address: addr)
  next unless token
  WatchlistItem.find_or_create_by!(user: demo, token: token)
end

puts "  Added watchlist items for demo user"
puts "Done! Login at demo@crypcop.com / password123"
