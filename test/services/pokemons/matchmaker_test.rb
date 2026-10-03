# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class MatchmakerTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @user = users(:user_one)
      @rival = users(:user_two)
    end

    test 'opponent pins a leaderboard neighbour' do
      assert_equal @rival, Matchmaker.new(@user).opponent
      assert_equal @rival.id, @user.reload.pinned_opponent_id
      assert_predicate @user.pinned_until, :future?
    end

    test 'opponent keeps the existing pin' do
      pin(@rival)

      assert_no_changes -> { @user.reload.pinned_until } do
        Matchmaker.new(@user).opponent
      end
    end

    test 'pinned_opponent never creates a pin' do
      assert_nil Matchmaker.new(@user).pinned_opponent
      assert_nil @user.reload.pinned_opponent_id
    end

    test 'expired pin is not used for battle' do
      pin(@rival, until_at: 1.minute.ago)

      assert_nil Matchmaker.new(@user).pinned_opponent
    end

    test 'pin on a user who left the leaderboard is dropped' do
      pin(User.find(101)) # users fixture user_101: no user_pokemons rows

      assert_nil Matchmaker.new(@user).pinned_opponent
      assert_equal @rival, Matchmaker.new(@user).opponent
    end

    test 'self pin is never used' do
      pin(@user)

      assert_nil Matchmaker.new(@user).pinned_opponent
    end

    test 'reroll is spent once per window' do
      matchmaker = Matchmaker.new(@user)

      assert matchmaker.reroll!
      assert_not matchmaker.reroll!
      assert_not matchmaker.reroll_available?
    end

    test 'reroll is available again after the window' do
      @user.update!(opponent_rerolled_at: (Balance::BATTLE_COOLDOWN + 1.minute).ago)

      assert Matchmaker.new(@user).reroll!
    end

    test 'reroll is refused while the team rests after a battle' do
      create_pokemon_battle(attacker: @user, defender: @rival)

      assert_not Matchmaker.new(@user).reroll!
      assert_nil @user.reload.opponent_rerolled_at
    end

    test 'release clears the pin' do
      pin(@rival)
      Matchmaker.new(@user).release!

      assert_nil @user.reload.pinned_opponent_id
    end

    private

    def pin(opponent, until_at: 1.hour.from_now)
      @user.update!(pinned_opponent_id: opponent.id, pinned_until: until_at)
    end
  end
end
