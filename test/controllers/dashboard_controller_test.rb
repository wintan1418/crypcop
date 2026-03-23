require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "dashboard requires authentication" do
    get dashboard_path
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "dashboard renders for authenticated user" do
    user = create(:user)
    sign_in user
    get dashboard_path
    assert_response :success
  end

  test "dashboard shows user data" do
    user = create(:user)
    token = create(:token)
    create(:scan, :manual, user: user, token: token)
    create(:watchlist_item, user: user, token: token)
    create(:alert, user: user, token: token)

    sign_in user
    get dashboard_path
    assert_response :success
  end
end
