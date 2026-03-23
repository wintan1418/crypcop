require "test_helper"
require "webmock/minitest"

class TokenDiscoveryJobTest < ActiveJob::TestCase
  test "enqueues broadcast jobs for new tokens" do
    stub_request(:get, "https://api.dexscreener.com/token-profiles/latest/v1")
      .to_return(
        status: 200,
        body: [
          { "chainId" => "solana", "tokenAddress" => "DiscoveryJobToken1" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_enqueued_with(job: BroadcastTokenJob) do
      TokenDiscoveryJob.perform_now
    end
  end
end
