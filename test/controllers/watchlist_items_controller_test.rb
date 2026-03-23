require "test_helper"

class WatchlistItemsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @token = create(:token)
  end

  test "index requires authentication" do
    get watchlist_items_path
    assert_redirected_to new_user_session_path
  end

  test "index renders for authenticated user" do
    sign_in @user
    get watchlist_items_path
    assert_response :success
  end

  test "create adds token to watchlist" do
    sign_in @user

    assert_difference "WatchlistItem.count", 1 do
      post watchlist_items_path(token_id: @token.id)
    end
  end

  test "destroy removes from watchlist" do
    sign_in @user
    item = create(:watchlist_item, user: @user, token: @token)

    assert_difference "WatchlistItem.count", -1 do
      delete watchlist_item_path(item)
    end
  end
end
