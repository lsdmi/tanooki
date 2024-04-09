require 'test_helper'

class DexLeaderboardTest < ActiveSupport::TestCase
  def setup
    @user = users(:user_110)
    @service = DexLeaderboard.new(@user)
  end

  test 'selected user index should be 11' do
    User.stub(:dex_leaders, User.all) do
      assert_equal User.first(3) + User.last(3), @service.call
    end
  end
end
