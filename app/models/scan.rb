class Scan < ApplicationRecord
  belongs_to :token
  belongs_to :user, optional: true

  validates :risk_score, presence: true, numericality: { in: 0..100 }
  validates :risk_level, presence: true
  validates :status, presence: true

  enum :risk_level, { safe: 0, low: 1, medium: 2, high: 3, critical: 4 }
  enum :scan_type, { auto: 0, manual: 1, deep: 2 }
  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed_scans, -> { where(status: :completed) }

  after_save :update_token_risk, if: :completed?

  private

  def update_token_risk
    token.update!(
      risk_score: risk_score,
      risk_level: risk_level,
      last_scanned_at: completed_at || Time.current
    )
  end
end
