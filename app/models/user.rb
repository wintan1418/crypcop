class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :scans, dependent: :nullify
  has_many :watchlist_items, dependent: :destroy
  has_many :watched_tokens, through: :watchlist_items, source: :token
  has_many :alerts, dependent: :destroy
  has_many :trust_votes, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :tracked_wallets, dependent: :destroy
  has_many :portfolio_holdings, dependent: :destroy
  has_many :api_keys, dependent: :destroy

  enum :tier, { free: 0, pro: 1 }

  def can_scan?
    pro? || daily_scan_count < 10
  end

  def increment_scan_count!
    reset_daily_scans_if_needed!
    increment!(:daily_scan_count)
  end

  def reset_daily_scans_if_needed!
    if daily_scan_reset_at.nil? || daily_scan_reset_at < Time.current.beginning_of_day
      update!(daily_scan_count: 0, daily_scan_reset_at: Time.current)
    end
  end

  def scans_remaining
    pro? ? Float::INFINITY : [ 10 - daily_scan_count, 0 ].max
  end
end
