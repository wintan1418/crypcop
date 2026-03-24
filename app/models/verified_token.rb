class VerifiedToken < ApplicationRecord
  belongs_to :token

  validates :badge_type, presence: true
  validates :contact_email, presence: true
  validates :status, presence: true

  enum :badge_type, { basic: 0, premium: 1, gold: 2 }
  enum :status, { pending: 0, approved: 1, rejected: 2, expired: 3 }

  PRICING = { basic: 200, premium: 350, gold: 500 }.freeze

  scope :active_badges, -> { where(status: :approved).where("expires_at > ?", Time.current) }

  def active?
    approved? && expires_at && expires_at > Time.current
  end

  def price
    PRICING[badge_type.to_sym] || 200
  end
end
