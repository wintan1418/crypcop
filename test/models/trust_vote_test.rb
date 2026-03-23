require "test_helper"

class TrustVoteTest < ActiveSupport::TestCase
  test "valid trust vote" do
    vote = build(:trust_vote)
    assert vote.valid?
  end

  test "unique user-token combination" do
    vote = create(:trust_vote)
    duplicate = build(:trust_vote, user: vote.user, token: vote.token)
    assert_not duplicate.valid?
  end

  test "vote enum" do
    assert build(:trust_vote, vote: :trust).trust?
    assert build(:trust_vote, :distrust).distrust?
  end
end
