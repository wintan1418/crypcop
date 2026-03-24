puts "Seeding CrypCop..."

# Real Solana tokens — blue chips and popular memecoins
real_tokens = [
  { mint_address: "So11111111111111111111111111111111111111112", name: "Wrapped SOL", symbol: "SOL" },
  { mint_address: "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v", name: "USD Coin", symbol: "USDC" },
  { mint_address: "Es9vMFrzaCERmJfrF4H2FYD4KCoNkY11McCe8BenwNYB", name: "Tether", symbol: "USDT" },
  { mint_address: "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263", name: "Bonk", symbol: "BONK" },
  { mint_address: "JUPyiwrYJFskUPiHa7hkeR8VUtAeFoSYbKedZNsDvCN", name: "Jupiter", symbol: "JUP" },
  { mint_address: "7GCihgDB8fe6KNjn2MYtkzZcRjQy3t9GHdC8uHYmW2hr", name: "Popcat", symbol: "POPCAT" },
  { mint_address: "EKpQGSJtjMFqKZ9KQanSqYXRcF8fBopzLHYxdM65zcjm", name: "dogwifhat", symbol: "WIF" },
  { mint_address: "rndrizKT3MK1iimdxRdWabcF7Zg7AR5T4nud4EkHBof", name: "Render", symbol: "RENDER" },
  { mint_address: "HZ1JovNiVvGrGNiiYvEozEVgZ58xaU3RKwX8eACQBCt3", name: "Pyth Network", symbol: "PYTH" },
  { mint_address: "hntyVP6YFm1Hg25TN9WGLqM12b8TQmcknKrdu1oxWux", name: "Helium", symbol: "HNT" },
  { mint_address: "SHDWyBxihqiCj6YekG2GUr7wqKLeLAMK1gHZck9pL6y", name: "Shadow", symbol: "SHDW" },
  { mint_address: "jtojtomepa8beP8AuQc6eXt5FriJwfFMwQx2v2f9mCL", name: "Jito", symbol: "JTO" },
  { mint_address: "TNSRxcUxoT9xBG3de7PiJyTDYu7kskLqcpddxnEJAS6", name: "Tensor", symbol: "TNSR" },
  { mint_address: "85VBFQZC9TZkfaptBWjvUw7YbZjy52A6mjtPGjstQAmQ", name: "W", symbol: "W" },
]

real_tokens.each do |data|
  next if Token.exists?(mint_address: data[:mint_address])

  token = Token.create!(
    mint_address: data[:mint_address],
    name: data[:name],
    symbol: data[:symbol],
    created_on_chain_at: Time.current
  )

  # Fetch live data from Solana APIs if keys are available
  if ENV["HELIUS_API_KEY"].present?
    begin
      Tokens::DataFetchService.new(token).fetch!
      result = Analysis::RiskCalculatorService.new(token).calculate
      token.scans.create!(
        risk_score: result[:risk_score],
        risk_level: result[:risk_level],
        ai_summary: result[:summary],
        flags: result[:flags],
        scan_type: :auto,
        status: :completed,
        completed_at: Time.current
      )
      puts "  #{token.name} (#{token.symbol}) — Risk: #{result[:risk_score]}/100 (#{result[:risk_level]})"
    rescue => e
      puts "  #{token.name} — fetch failed: #{e.message}"
    end
  else
    puts "  #{token.name} (#{token.symbol}) — created (no API key, skipping live data)"
  end
end

# Seed known whale/smart money wallets for the Smart Money feed
smart_wallets = [
  { wallet_address: "5Q544fKrFoe6tsEbD7S8EmxGTJYAKtTVhAW5Q5pge4j1", label: "Raydium Authority", is_whale: true, is_smart_money: true },
  { wallet_address: "HN7cABqLq46Es1jh92dQQisAi5YqpFCuHkYge4fPLBiN", label: "Wintermute", is_whale: true, is_smart_money: true },
  { wallet_address: "AC5RDfQFmDS1deWZos921JfqscXdByf8BKHs5ACWjtW2", label: "Jump Trading", is_whale: true, is_smart_money: true },
]

smart_wallets.each do |data|
  # Create a system-level tracked wallet (no user association needed for public smart money feed)
  # These will be tracked by the system for the Smart Money feed
  # For now, skip if no admin user exists
  admin = User.first
  next unless admin

  wallet = admin.tracked_wallets.find_or_create_by!(wallet_address: data[:wallet_address]) do |w|
    w.label = data[:label]
    w.is_whale = data[:is_whale]
    w.is_smart_money = data[:is_smart_money]
    w.notify_on_buy = false
    w.notify_on_sell = false
  end
  puts "  Tracking: #{wallet.label} (#{wallet.wallet_address[0..12]}...)"
end

puts "\nDone! #{Token.count} tokens, #{TrackedWallet.count} tracked wallets"
