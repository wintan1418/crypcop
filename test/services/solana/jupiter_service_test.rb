require "test_helper"
require "webmock/minitest"

class Solana::JupiterServiceTest < ActiveSupport::TestCase
  setup do
    @service = Solana::JupiterService.new
  end

  test "get_price returns price data" do
    stub_request(:get, "https://api.jup.ag/price/v2?ids=abc123")
      .to_return(
        status: 200,
        body: {
          "data" => {
            "abc123" => { "price" => "0.001234" }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.get_price("abc123")
    assert_not_nil result
    assert_in_delta 0.001234, result[:price_usd], 0.000001
  end

  test "get_price returns nil on error" do
    stub_request(:get, "https://api.jup.ag/price/v2?ids=bad")
      .to_return(status: 500, body: "error")

    result = @service.get_price("bad")
    assert_nil result
  end

  test "get_prices returns batch prices" do
    stub_request(:get, "https://api.jup.ag/price/v2?ids=abc,def")
      .to_return(
        status: 200,
        body: {
          "data" => {
            "abc" => { "price" => "1.5" },
            "def" => { "price" => "0.05" }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = @service.get_prices([ "abc", "def" ])
    assert_equal 2, result.size
    assert_in_delta 1.5, result["abc"][:price_usd], 0.01
  end
end
