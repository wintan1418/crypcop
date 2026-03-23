require "test_helper"

class FeedControllerTest < ActionDispatch::IntegrationTest
  test "feed page renders" do
    get feed_path
    assert_response :success
  end

  test "feed shows scanned tokens" do
    create(:token, name: "SafeCoin", risk_level: :safe, last_scanned_at: Time.current)
    create(:token, :unscanned)

    get feed_path
    assert_response :success
  end

  test "feed filters by risk level" do
    create(:token, risk_level: :safe, last_scanned_at: Time.current)
    create(:token, :high_risk, last_scanned_at: Time.current)

    get feed_path(risk: "safe")
    assert_response :success
  end
end
