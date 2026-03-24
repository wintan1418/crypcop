class Token < ApplicationRecord
  include PgSearch::Model

  has_many :scans, dependent: :destroy
  has_many :watchlist_items, dependent: :destroy
  has_many :watchers, through: :watchlist_items, source: :user
  has_many :trust_votes, dependent: :destroy
  has_many :alerts, dependent: :destroy
  has_many :verified_tokens, dependent: :destroy

  validates :mint_address, presence: true, uniqueness: true

  enum :risk_level, { safe: 0, low: 1, medium: 2, high: 3, critical: 4 }

  pg_search_scope :search_by_name_or_symbol,
    against: [ :name, :symbol, :mint_address ],
    using: { tsearch: { prefix: true } }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_risk, ->(level) { where(risk_level: level) }
  scope :scanned, -> { where.not(last_scanned_at: nil) }
  scope :unscanned, -> { where(last_scanned_at: nil) }

  def trust_count
    trust_votes.where(vote: :trust).count
  end

  def distrust_count
    trust_votes.where(vote: :distrust).count
  end

  def trust_ratio
    total = trust_count + distrust_count
    return 0 if total.zero?
    (trust_count.to_f / total * 100).round
  end

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

  def risk_bg_color
    case risk_level
    when "safe" then "bg-green-500/20 border-green-500/30"
    when "low" then "bg-yellow-500/20 border-yellow-500/30"
    when "medium" then "bg-orange-500/20 border-orange-500/30"
    when "high" then "bg-red-500/20 border-red-500/30"
    when "critical" then "bg-red-700/20 border-red-700/30"
    else "bg-gray-500/20 border-gray-500/30"
    end
  end

  def age_text
    return "Unknown" unless created_on_chain_at
    seconds = Time.current - created_on_chain_at
    if seconds < 60
      "#{seconds.to_i}s ago"
    elsif seconds < 3600
      "#{(seconds / 60).to_i}m ago"
    elsif seconds < 86400
      "#{(seconds / 3600).to_i}h ago"
    else
      "#{(seconds / 86400).to_i}d ago"
    end
  end
end
