require "test_helper"

class ScanTest < ActiveSupport::TestCase
  test "valid scan" do
    scan = build(:scan)
    assert scan.valid?
  end

  test "requires risk_score" do
    scan = build(:scan, risk_score: nil)
    assert_not scan.valid?
  end

  test "risk_score must be 0-100" do
    assert_not build(:scan, risk_score: -1).valid?
    assert_not build(:scan, risk_score: 101).valid?
    assert build(:scan, risk_score: 0).valid?
    assert build(:scan, risk_score: 100).valid?
  end

  test "belongs to token" do
    scan = create(:scan)
    assert_not_nil scan.token
  end

  test "user is optional" do
    scan = build(:scan, user: nil)
    assert scan.valid?
  end

  test "status enum" do
    scan = build(:scan, :pending)
    assert scan.pending?
  end

  test "scan_type enum" do
    scan = build(:scan, scan_type: :manual)
    assert scan.manual?
  end

  test "completed scope" do
    completed = create(:scan, status: :completed)
    pending = create(:scan, :pending)
    assert_includes Scan.completed_scans, completed
    assert_not_includes Scan.completed_scans, pending
  end

  test "updates token risk on completed save" do
    token = create(:token, risk_score: 10, risk_level: :safe)
    create(:scan, token: token, risk_score: 75, risk_level: :high, status: :completed, completed_at: Time.current)
    token.reload
    assert_equal 75, token.risk_score
    assert token.high?
  end
end
