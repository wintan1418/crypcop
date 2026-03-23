class Alert < ApplicationRecord
  belongs_to :user
  belongs_to :token

  validates :alert_type, presence: true
  validates :title, presence: true
  validates :message, presence: true

  enum :alert_type, {
    risk_increase: 0,
    risk_decrease: 1,
    price_change: 2,
    liquidity_removed: 3,
    mint_authority_change: 4,
    new_scan: 5
  }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }

  def read?
    read_at.present?
  end

  def mark_read!
    update!(read_at: Time.current)
  end
end
