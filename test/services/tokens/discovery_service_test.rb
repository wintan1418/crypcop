require "test_helper"
require "webmock/minitest"

class Tokens::DiscoveryServiceTest < ActiveJob::TestCase
  setup do
    @service = Tokens::DiscoveryService.new
  end

  test "discovers new solana tokens" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(
        status: 200,
        body: [
          { "chainId" => "solana", "tokenAddress" => "NewToken111", "icon" => "https://img.com/a.png", "description" => "Test Token" },
          { "chainId" => "solana", "tokenAddress" => "NewToken222", "icon" => nil, "description" => "Another Token" },
          { "chainId" => "ethereum", "tokenAddress" => "EthToken333" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Token.count", 2 do
      new_tokens = @service.discover!
      assert_equal 2, new_tokens.size
    end

    assert Token.exists?(mint_address: "NewToken111")
    assert Token.exists?(mint_address: "NewToken222")
    assert_not Token.exists?(mint_address: "EthToken333")
  end

  test "skips already existing tokens" do
    create(:token, mint_address: "ExistingToken")

    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(
        status: 200,
        body: [
          { "chainId" => "solana", "tokenAddress" => "ExistingToken" },
          { "chainId" => "solana", "tokenAddress" => "BrandNew123" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "Token.count", 1 do
      @service.discover!
    end
  end

  test "handles empty response" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

    assert_no_difference "Token.count" do
      result = @service.discover!
      assert_equal [], result
    end
  end

  test "enqueues data fetch jobs" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(
        status: 200,
        body: [
          { "chainId" => "solana", "tokenAddress" => "JobToken111" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_enqueued_with(job: TokenDataFetchJob) do
      @service.discover!
    end
  end
end
