# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Candies
    class GrantTest < ActiveSupport::TestCase
      setup do
        @user = users(:user_one)
        @profile = @user.trainer_profile
        @profile.update!(candies: 0)
        CandyTransaction.where(user: @user).delete_all
      end

      test 'adds candies and writes a ledger row' do
        Grant.call(@user, amount: 5, reason: 'daily_quest')

        assert_equal 5, @profile.reload.candies
        row = CandyTransaction.find_by!(user: @user, reason: 'daily_quest')

        assert_equal 5, row.amount
      end
    end
  end
end
