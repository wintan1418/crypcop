class PortfolioHolding < ApplicationRecord
  belongs_to :user
  belongs_to :token, optional: true

  validates :wallet_address, presence: true

  enum :risk_level, { safe: 0, low: 1, medium: 2, high: 3, critical: 4 }

  scope :by_risk, -> { order(risk_score: :desc) }
  scope :risky, -> { where("risk_score > 50") }

  def risk_color
    case risk_level
    when "safe" then "text-green-400"
    when "low" then "text-yellow-400"
    when "medium" then "text-orange-400"
    when "high" then "text-red-500"
    when "critical" then "text-red-700"
    else "text-gray-400"
    end
  end
end
