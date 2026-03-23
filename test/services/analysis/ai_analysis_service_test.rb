require "test_helper"
require "webmock/minitest"

class Analysis::AiAnalysisServiceTest < ActiveSupport::TestCase
  setup do
    @token = create(:token, :high_risk)
    @scan = create(:scan, :pending, token: @token)
  end

  test "falls back to deterministic scorer when no API key" do
    ENV.delete("ANTHROPIC_API_KEY")
    service = Analysis::AiAnalysisService.new(@token, @scan)
    result = service.analyze!

    assert result[:risk_score].is_a?(Integer)
    assert_includes [ :safe, :low, :medium, :high, :critical ], result[:risk_level]
    assert result[:summary].present?
    assert result[:flags].is_a?(Array)
  end

  test "calls Claude API when key is set" do
    ENV["ANTHROPIC_API_KEY"] = "test-key-123"

    claude_response = {
      "content" => [ {
        "text" => {
          "risk_score" => 75,
          "risk_level" => "high",
          "summary" => "This token shows multiple high-risk indicators.",
          "flags" => [ "Mint authority not revoked", "Low liquidity" ],
          "detailed_analysis" => {
            "authority_risk" => "High — mint authority active",
            "liquidity_risk" => "High — under $5000",
            "holder_risk" => "Medium",
            "overall" => "High risk token"
          }
        }.to_json
      } ]
    }

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: claude_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Analysis::AiAnalysisService.new(@token, @scan)
    result = service.analyze!

    assert_equal 75, result[:risk_score]
    assert_equal :high, result[:risk_level]
    assert_includes result[:summary], "high-risk"
    assert_equal 2, result[:flags].size
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
  end

  test "falls back on API error" do
    ENV["ANTHROPIC_API_KEY"] = "test-key-123"

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: "Internal Server Error")

    service = Analysis::AiAnalysisService.new(@token, @scan)
    result = service.analyze!

    # Should get a valid result from fallback
    assert result[:risk_score].is_a?(Integer)
    assert result[:summary].present?
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
  end

  test "clamps risk score to 0-100" do
    ENV["ANTHROPIC_API_KEY"] = "test-key-123"

    claude_response = {
      "content" => [ {
        "text" => {
          "risk_score" => 150,
          "risk_level" => "critical",
          "summary" => "Extremely risky",
          "flags" => [],
          "detailed_analysis" => {}
        }.to_json
      } ]
    }

    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: claude_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    service = Analysis::AiAnalysisService.new(@token, @scan)
    result = service.analyze!

    assert_equal 100, result[:risk_score]
  ensure
    ENV.delete("ANTHROPIC_API_KEY")
  end
end
