require "test_helper"

class AlertDispatchJobTest < ActiveSupport::TestCase
  test "creates alerts for watchers when risk increases" do
    token = create(:token)
    user = create(:user)
    create(:watchlist_item, user: user, token: token, notify_on_risk_change: true)

    assert_difference "Alert.count", 1 do
      AlertDispatchJob.perform_now(token.id, 20, 65)
    end

    alert = Alert.last
    assert_equal "risk_increase", alert.alert_type
    assert_includes alert.title, "increased"
  end

  test "creates alerts for watchers when risk decreases" do
    token = create(:token)
    user = create(:user)
    create(:watchlist_item, user: user, token: token, notify_on_risk_change: true)

    assert_difference "Alert.count", 1 do
      AlertDispatchJob.perform_now(token.id, 65, 20)
    end

    alert = Alert.last
    assert_equal "risk_decrease", alert.alert_type
  end

  test "skips watchers with notifications disabled" do
    token = create(:token)
    user = create(:user)
    create(:watchlist_item, user: user, token: token, notify_on_risk_change: false)

    assert_no_difference "Alert.count" do
      AlertDispatchJob.perform_now(token.id, 20, 65)
    end
  end

  test "does nothing with no watchers" do
    token = create(:token)

    assert_no_difference "Alert.count" do
      AlertDispatchJob.perform_now(token.id, 20, 65)
    end
  end
end
