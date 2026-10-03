# frozen_string_literal: true

require 'test_helper'

module Pokemons
  # Two requests at the same moment, each on its own database connection, as two tabs or devices would send them.
  # Threads cannot see each other's rows inside the usual per-test transaction, so this class commits for real.
  class CooldownRaceTest < ActiveSupport::TestCase
    self.use_transactional_tests = false

    setup do
      @user = users(:user_one)
      @user.update!(pokemon_last_catch: 5.hours.ago, pokemon_last_training: 5.hours.ago)
    end

    teardown do
      PokemonEncounter.where(user_id: @user.id).delete_all
      PokemonBattle.where(attacker_id: @user.id).delete_all
      # Fixture rows were changed outside a transaction; make the next test class reload them.
      ActiveRecord::FixtureSet.reset_cache
    end

    test 'two claims at once run the action once, even when it is slow' do
      runs = Concurrent::AtomicFixnum.new
      race do
        CooldownClaim.call(fresh_user, :training) do
          sleep 0.2
          runs.increment
        end
      end

      assert_equal 1, runs.value
    end

    test 'two catches at once catch one pokemon' do
      tokens = Array.new(2) { PokemonEncounter.roll!(pokemon: pokemons(:two), user: @user).catch_token }
      results = race { |i| Catch.new(fresh_user, tokens[i]).call }

      assert_equal 1, results.compact.size
      assert_equal 1, PokemonEncounter.where(user: @user).caught.count
    end

    test 'two trainings at once train once' do
      results = race { Training.new(fresh_user, user_pokemons(:one).id).call }

      assert_equal 1, results.compact.size
    end

    test 'two battles at once fight once' do
      Matchmaker.new(@user).opponent
      results = race { BattleStart.new(fresh_user).call }

      assert_equal 1, results.count(:fought)
      assert_equal 1, PokemonBattle.where(attacker_id: @user.id).count
    end

    private

    # Each thread loads its own copy of the user, as separate requests would.
    def fresh_user
      User.find(@user.id)
    end

    def race
      barrier = Concurrent::CyclicBarrier.new(2)
      threads = Array.new(2) do |i|
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            barrier.wait
            yield(i)
          end
        end
      end
      threads.map(&:value)
    end
  end
end
