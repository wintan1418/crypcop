require "test_helper"
require "webmock/minitest"

class SearchControllerTest < ActionDispatch::IntegrationTest
  test "search page renders" do
    get search_path
    assert_response :success
  end

  test "search by token name" do
    token = create(:token, name: "TestCoin", symbol: "TST")
    get search_path(q: "TestCoin")
    assert_response :success
  end

  test "search by existing mint address redirects to token page" do
    token = create(:token, mint_address: "So11111111111111111111111111111111111111112")
    get search_path(q: "So11111111111111111111111111111111111111112")
    assert_redirected_to token_path("So11111111111111111111111111111111111111112")
  end

  test "search by unknown mint address creates token and redirects" do
    address = "DezXAZ8z7PnrnRJjz3wXBoRgixCa6xjnB7YaB1pPB263"

    assert_difference "Token.count", 1 do
      get search_path(q: address)
    end

    assert_redirected_to token_path(address)
    assert_match "Scanning now", flash[:notice]
  end

  test "empty search shows no results" do
    get search_path(q: "")
    assert_response :success
  end
end
