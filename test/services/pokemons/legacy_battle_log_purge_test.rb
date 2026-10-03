# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class LegacyBattleLogPurgeTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      @other_bodies = ActionText::RichText.where.not(record_type: LegacyBattleLogPurge::RECORD_TYPE).count
    end

    test 'deletes every log body in batches, orphans included, and nothing else' do
      2.times { converted_log }
      body_for(new_log).record.delete
      totals = []

      deleted = LegacyBattleLogPurge.new(batch_size: 2, pause: 0).call { |total| totals << total }

      assert_equal [3, [2, 3]], [deleted, totals]
      assert_equal [@other_bodies, 2], [ActionText::RichText.count, PokemonBattleLog.count]
    end

    test 'refuses to start while a log is not converted' do
      converted_log
      body_for(new_log)
      purge = LegacyBattleLogPurge.new(pause: 0)

      assert_raises(LegacyBattleLogPurge::Unconverted) { purge.call }
      assert_equal [1, 2], [purge.unconverted, purge.remaining]
    end

    private

    def converted_log
      create_pokemon_battle(attacker: @attacker, defender: @defender, engine_version: PokemonBattle::LEGACY_VERSION)
      body_for(new_log)
    end

    def new_log
      PokemonBattleLog.create!(attacker: @attacker, defender: @defender, winner: @attacker)
    end

    def body_for(log)
      ActionText::RichText.create!(record: log, name: 'details', body: '<div>log</div>')
    end
  end
end
