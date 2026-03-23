require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = build(:user)
    assert user.valid?
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
  end

  test "requires unique email" do
    create(:user, email: "test@example.com")
    user = build(:user, email: "test@example.com")
    assert_not user.valid?
  end

  test "default tier is free" do
    user = create(:user)
    assert user.free?
  end

  test "can_scan? returns true for free user under limit" do
    user = create(:user, daily_scan_count: 5)
    assert user.can_scan?
  end

  test "can_scan? returns false for free user at limit" do
    user = create(:user, daily_scan_count: 10)
    assert_not user.can_scan?
  end

  test "can_scan? always returns true for pro user" do
    user = create(:user, :pro, daily_scan_count: 100)
    assert user.can_scan?
  end

  test "increment_scan_count!" do
    user = create(:user, daily_scan_count: 3, daily_scan_reset_at: Time.current)
    user.increment_scan_count!
    assert_equal 4, user.reload.daily_scan_count
  end

  test "reset_daily_scans_if_needed! resets at midnight" do
    user = create(:user, daily_scan_count: 8, daily_scan_reset_at: 1.day.ago)
    user.reset_daily_scans_if_needed!
    assert_equal 0, user.reload.daily_scan_count
  end

  test "scans_remaining for free user" do
    user = create(:user, daily_scan_count: 7)
    assert_equal 3, user.scans_remaining
  end

  test "scans_remaining for pro user is infinity" do
    user = create(:user, :pro)
    assert_equal Float::INFINITY, user.scans_remaining
  end

  test "has_many associations" do
    user = create(:user)
    assert_respond_to user, :scans
    assert_respond_to user, :watchlist_items
    assert_respond_to user, :watched_tokens
    assert_respond_to user, :alerts
    assert_respond_to user, :trust_votes
    assert_respond_to user, :subscription
  end
end
