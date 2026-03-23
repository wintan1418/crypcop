require "test_helper"

class DailyScanResetJobTest < ActiveSupport::TestCase
  test "resets scan counts for all users" do
    user1 = create(:user, daily_scan_count: 8)
    user2 = create(:user, daily_scan_count: 3)
    user3 = create(:user, daily_scan_count: 0)

    DailyScanResetJob.perform_now

    assert_equal 0, user1.reload.daily_scan_count
    assert_equal 0, user2.reload.daily_scan_count
    assert_equal 0, user3.reload.daily_scan_count
  end
end
