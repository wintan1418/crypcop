require "test_helper"

class WatchlistItemTest < ActiveSupport::TestCase
  test "valid watchlist item" do
    item = build(:watchlist_item)
    assert item.valid?
  end

  test "unique user-token combination" do
    item = create(:watchlist_item)
    duplicate = build(:watchlist_item, user: item.user, token: item.token)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "already watching this token"
  end
end
