class ApiKey < ApplicationRecord
  belongs_to :user

  validates :key, presence: true, uniqueness: true
  validates :tier, presence: true

  enum :tier, { free_api: 0, pro_api: 1, enterprise_api: 2 }

  before_validation :generate_key, on: :create

  scope :active_keys, -> { where(active: true) }

  TIER_LIMITS = { free_api: 100, pro_api: 10_000, enterprise_api: 100_000 }.freeze

  def can_call?
    return false unless active?
    reset_if_needed!
    calls_today < calls_limit
  end

  def record_call!
    reset_if_needed!
    increment!(:calls_today)
    update_columns(last_used_at: Time.current)
  end

  def calls_remaining
    [ calls_limit - calls_today, 0 ].max
  end

  private

  def generate_key
    self.key = "ck_#{SecureRandom.hex(24)}"
    self.calls_limit = TIER_LIMITS[tier.to_sym] || 100
  end

  def reset_if_needed!
    if calls_reset_at.nil? || calls_reset_at < Time.current.beginning_of_day
      update_columns(calls_today: 0, calls_reset_at: Time.current)
    end
  end
end
