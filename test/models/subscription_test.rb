require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "valid subscription" do
    subscription = build(:subscription)
    assert subscription.valid?
  end

  test "requires stripe_subscription_id" do
    subscription = build(:subscription, stripe_subscription_id: nil)
    assert_not subscription.valid?
  end

  test "unique stripe_subscription_id" do
    create(:subscription, stripe_subscription_id: "sub_123")
    duplicate = build(:subscription, stripe_subscription_id: "sub_123")
    assert_not duplicate.valid?
  end

  test "status enum" do
    assert build(:subscription, status: :active).active?
    assert build(:subscription, :canceled).canceled?
  end

  test "active_or_trialing?" do
    assert build(:subscription, status: :active).active_or_trialing?
    assert build(:subscription, status: :trialing).active_or_trialing?
    assert_not build(:subscription, :canceled).active_or_trialing?
  end

  test "syncs user tier to pro when active" do
    user = create(:user, tier: :free)
    create(:subscription, user: user, status: :active)
    assert user.reload.pro?
  end

  test "syncs user tier to free when canceled" do
    user = create(:user, tier: :pro)
    sub = create(:subscription, user: user, status: :active)
    sub.update!(status: :canceled)
    assert user.reload.free?
  end
end
