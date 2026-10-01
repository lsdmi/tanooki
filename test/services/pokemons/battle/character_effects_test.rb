# frozen_string_literal: true

require 'test_helper'

module Pokemons
  module Battle
    class CharacterEffectsTest < ActiveSupport::TestCase
      Fighter = Struct.new(:id, :character)

      setup do
        @winner_team = SideTeam.new([{ id: 7, tiredness: 1.0 }])
        @loser = Fighter.new(8, 'calm')
      end

      test 'hardy winner rests on its own side' do
        CharacterEffects.apply_victory(Fighter.new(7, 'hardy'), @loser, @winner_team)

        assert_in_delta 0.9, @winner_team.team.first[:tiredness]
      end

      test 'agile loser tires the winner on its own side' do
        CharacterEffects.apply_victory(Fighter.new(7, 'calm'), Fighter.new(8, 'agile'), @winner_team)

        assert_in_delta 1.1, @winner_team.team.first[:tiredness]
      end
    end
  end
end
