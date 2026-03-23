class WalletTransaction < ApplicationRecord
  belongs_to :tracked_wallet
  belongs_to :token, optional: true

  validates :tx_signature, presence: true, uniqueness: true
  validates :tx_type, presence: true

  enum :tx_type, { buy: 0, sell: 1, transfer_in: 2, transfer_out: 3 }

  scope :recent, -> { order(transacted_at: :desc) }
  scope :buys, -> { where(tx_type: :buy) }
  scope :sells, -> { where(tx_type: :sell) }
end
