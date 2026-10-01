# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class CooldownClaimTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @user.update!(pokemon_last_training: 5.hours.ago)
    end

    test 'runs the action and starts the cooldown' do
      assert_equal :trained, CooldownClaim.call(@user, :training) { :trained }
      assert_predicate @user.reload, :pokemon_training_on_cooldown?
    end

    test 'skips the action while on cooldown' do
      @user.update!(pokemon_last_training: 1.hour.ago)

      assert_nil CooldownClaim.call(@user, :training) { flunk 'must not run on cooldown' }
    end

    test 'a failed action does not start the cooldown' do
      CooldownClaim.call(@user, :training) { nil }

      assert_not_predicate @user.reload, :pokemon_training_on_cooldown?
    end
  end
end
