# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Battle
    class CharacterTraitsTest < ActiveSupport::TestCase
      Character = Struct.new(:character, :battle_experience)

      setup do
        @attacker = { power: 10, luck: 1.0, experience: 0, type: 1, raw_total: 0 }
        @defender = { power: 8, luck: 1.0, experience: 0, type: 2, raw_total: 0 }
        @team = [
          { id: 1, tiredness: 0.5 },
          { id: 2, tiredness: 0.3 }
        ]
        @character = user_pokemons(:one)
      end

      test 'ambitious character with lucky opponent sets luck and raw_total' do
        opponent = Character.new('lucky', 0)
        CharacterTraits.handle_ambitious_character(@attacker, opponent)

        assert_in_delta 1.0, @attacker[:luck]
        assert_in_delta 10, @attacker[:raw_total]
      end

      test 'ambitious character with non-lucky opponent reduces luck and raw_total' do
        opponent = Character.new('unlucky', 0)
        CharacterTraits.handle_ambitious_character(@attacker, opponent)

        assert_in_delta 0.9, @attacker[:luck]
        assert_in_delta 9, @attacker[:raw_total]
      end

      test 'should handle prideful character correctly' do
        CharacterTraits.handle_prideful_character(@attacker)

        assert_in_delta (10 / 1.2), @attacker[:power]
        assert_in_delta (@attacker[:power] + @attacker[:experience]) * @attacker[:luck], @attacker[:raw_total]
      end

      test 'should handle patient character correctly' do
        CharacterTraits.handle_patient_character(@attacker, @defender)

        assert_equal 1, @defender[:type]

        @attacker[:type] = 3
        @defender[:type] = 2
        CharacterTraits.handle_patient_character(@attacker, @defender)

        assert_equal 2, @defender[:type]
      end

      test 'should handle decisive character correctly' do
        CharacterTraits.handle_decisive_character(@attacker, @defender)

        assert_equal 1, @attacker[:type]

        @attacker[:type] = 2
        @defender[:type] = 1
        CharacterTraits.handle_decisive_character(@attacker, @defender)

        assert_in_delta 2.1, @attacker[:type]
      end

      test 'should handle hardy character correctly' do
        CharacterTraits.handle_hardy_character(@team, @team.first)

        assert_in_delta 0.4, @team.first[:tiredness]
      end

      test 'should handle persistent character correctly' do
        CharacterTraits.handle_persistent_character(@character, 100)

        assert_equal 2, @character.battle_experience

        CharacterTraits.handle_persistent_character(@character, 120)

        assert_equal 2, @character.battle_experience
      end
    end
  end
end
