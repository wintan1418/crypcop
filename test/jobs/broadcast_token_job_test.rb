require "test_helper"

class BroadcastTokenJobTest < ActiveSupport::TestCase
  test "broadcasts token to turbo stream" do
    token = create(:token)

    assert_nothing_raised do
      BroadcastTokenJob.perform_now(token.id)
    end
  end
end
