require "test_helper"

class AlertTest < ActiveSupport::TestCase
  test "valid alert" do
    alert = build(:alert)
    assert alert.valid?
  end

  test "requires title" do
    alert = build(:alert, title: nil)
    assert_not alert.valid?
  end

  test "requires message" do
    alert = build(:alert, message: nil)
    assert_not alert.valid?
  end

  test "alert_type enum" do
    alert = build(:alert, alert_type: :liquidity_removed)
    assert alert.liquidity_removed?
  end

  test "unread scope" do
    unread = create(:alert)
    read = create(:alert, :read)
    assert_includes Alert.unread, unread
    assert_not_includes Alert.unread, read
  end

  test "mark_read!" do
    alert = create(:alert)
    assert_nil alert.read_at
    alert.mark_read!
    assert_not_nil alert.reload.read_at
  end

  test "read?" do
    assert_not build(:alert).read?
    assert build(:alert, :read).read?
  end
end
