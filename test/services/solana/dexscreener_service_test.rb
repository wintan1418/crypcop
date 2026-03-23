require "test_helper"
require "webmock/minitest"

class Solana::DexscreenerServiceTest < ActiveSupport::TestCase
  setup do
    @service = Solana::DexscreenerService.new
  end

  test "latest_token_profiles returns array" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(
        status: 200,
        body: [
          { "chainId" => "solana", "tokenAddress" => "abc123", "icon" => "https://img.com/a.png" },
          { "chainId" => "ethereum", "tokenAddress" => "eth456" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.latest_token_profiles
    assert_equal 2, result.size
    assert_equal "abc123", result.first["tokenAddress"]
  end

  test "latest_token_profiles returns empty on error" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(status: 500, body: "Internal Server Error")

    result = @service.latest_token_profiles
    assert_equal [], result
  end

  test "get_pairs returns pair data" do
    stub_request(:get, "https://api.dexscreener.com/tokens/v1/solana/abc123")
      .to_return(
        status: 200,
        body: [
          {
            "baseToken" => { "name" => "TestCoin", "symbol" => "TEST" },
            "priceUsd" => "0.001234",
            "marketCap" => 50000,
            "liquidity" => { "usd" => 10000 },
            "volume" => { "h24" => 5000 }
          }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.get_pairs("abc123")
    assert_equal 1, result.size
    assert_equal "TestCoin", result.first.dig("baseToken", "name")
  end

  test "get_pairs returns empty on error" do
    stub_request(:get, "https://api.dexscreener.com/tokens/v1/solana/bad")
      .to_return(status: 404, body: "Not found")

    result = @service.get_pairs("bad")
    assert_equal [], result
  end
end
