require "test_helper"

class TokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @token = create(:token)
    @user = create(:user)
  end

  test "show renders token detail" do
    get token_path(@token.mint_address)
    assert_response :success
  end

  test "scan requires authentication" do
    post scan_token_path(@token.mint_address)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "scan creates a pending scan for authenticated user" do
    sign_in @user

    assert_difference "Scan.count", 1 do
      post scan_token_path(@token.mint_address)
    end

    assert_redirected_to token_path(@token.mint_address)
    assert_equal "Scan initiated. Results will appear shortly.", flash[:notice]
  end

  test "scan increments user scan count" do
    sign_in @user
    post scan_token_path(@token.mint_address)
    assert_equal 1, @user.reload.daily_scan_count
  end

  test "scan rejects when free user at limit" do
    user = create(:user, :scan_limit_reached)
    sign_in user

    assert_no_difference "Scan.count" do
      post scan_token_path(@token.mint_address)
    end

    assert_redirected_to token_path(@token.mint_address)
    assert_match "Daily scan limit", flash[:alert]
  end

  test "scan allows pro user regardless of count" do
    user = create(:user, :pro, daily_scan_count: 100)
    sign_in user

    assert_difference "Scan.count", 1 do
      post scan_token_path(@token.mint_address)
    end
  end

  test "vote requires authentication" do
    post vote_token_path(@token.mint_address, vote: :trust)
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "vote creates trust vote" do
    sign_in @user

    assert_difference "TrustVote.count", 1 do
      post vote_token_path(@token.mint_address, vote: :trust)
    end

    assert_equal "trust", TrustVote.last.vote
  end

  test "vote updates existing vote" do
    sign_in @user
    create(:trust_vote, user: @user, token: @token, vote: :trust)

    assert_no_difference "TrustVote.count" do
      post vote_token_path(@token.mint_address, vote: :distrust)
    end

    assert_equal "distrust", @user.trust_votes.find_by(token: @token).vote
  end

  test "vote rejects invalid vote value" do
    sign_in @user
    post vote_token_path(@token.mint_address, vote: :invalid)
    assert_match "Invalid vote", flash[:alert]
  end
end
