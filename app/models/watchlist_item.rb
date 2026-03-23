class WatchlistItem < ApplicationRecord
  belongs_to :user
  belongs_to :token

  validates :user_id, uniqueness: { scope: :token_id, message: "already watching this token" }
end
