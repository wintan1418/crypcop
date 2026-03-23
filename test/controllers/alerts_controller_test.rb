require "test_helper"

class AlertsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    @token = create(:token)
  end

  test "index requires authentication" do
    get alerts_path
    assert_redirected_to new_user_session_path
  end

  test "index renders alerts" do
    sign_in @user
    create(:alert, user: @user, token: @token)
    get alerts_path
    assert_response :success
  end

  test "mark_read marks single alert" do
    sign_in @user
    alert = create(:alert, user: @user, token: @token)

    patch mark_read_alert_path(alert)
    assert alert.reload.read?
  end

  test "mark_all_read marks all unread alerts" do
    sign_in @user
    a1 = create(:alert, user: @user, token: @token)
    a2 = create(:alert, user: @user, token: @token)

    post mark_all_read_alerts_path
    assert a1.reload.read?
    assert a2.reload.read?
  end
end
