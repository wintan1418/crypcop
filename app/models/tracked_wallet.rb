class TrackedWallet < ApplicationRecord
  belongs_to :user
  has_many :wallet_transactions, dependent: :destroy

  validates :wallet_address, presence: true
  validates :wallet_address, uniqueness: { scope: :user_id, message: "already being tracked" }
  validates :wallet_address, format: { with: /\A[1-9A-HJ-NP-Za-km-z]{32,44}\z/, message: "is not a valid Solana address" }

  scope :smart_money, -> { where(is_smart_money: true) }
  scope :whales, -> { where(is_whale: true) }
  scope :recent_activity, -> { order(last_activity_at: :desc) }
end
