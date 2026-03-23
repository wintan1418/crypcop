class Subscription < ApplicationRecord
  belongs_to :user

  validates :stripe_subscription_id, presence: true, uniqueness: true
  validates :stripe_price_id, presence: true
  validates :status, presence: true

  enum :status, { active: 0, past_due: 1, canceled: 2, trialing: 3 }

  after_save :sync_user_tier

  def active_or_trialing?
    active? || trialing?
  end

  private

  def sync_user_tier
    if active_or_trialing?
      user.update!(tier: :pro)
    else
      user.update!(tier: :free)
    end
  end
end
