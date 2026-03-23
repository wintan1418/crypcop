class TrustVote < ApplicationRecord
  belongs_to :user
  belongs_to :token

  validates :vote, presence: true
  validates :user_id, uniqueness: { scope: :token_id, message: "already voted on this token" }

  enum :vote, { trust: 0, distrust: 1 }
end
