# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleReplayScriptTest < ActiveSupport::TestCase
    include PokemonBattleHelpers

    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      UserPokemon.create!(user: @attacker, pokemon: pokemons(:four), character: :brave, battle_experience: 40)
      UserPokemon.create!(user: @defender, pokemon: pokemons(:five), character: :hardy, battle_experience: 10)
      Matchmaker.new(@attacker).opponent
      BattleStart.new(@attacker).call
      @battle = PokemonBattle.last
      @view = Object.new
      def @view.url_for(_)
        '/sprite.gif'
      end
    end

    test 'builds fighters with max HP for version 2' do
      script = BattleReplayScript.new(@battle, view: @view).as_json

      assert script[:hp]
      assert_equal @battle.events, script[:events]
      assert(script[:fighters].values.all? { |fighter| fighter[:maxHp].positive? })
    end

    test 'includes replay labels and hardy flavor' do
      script = BattleReplayScript.new(@battle, view: @view).as_json
      hardy = script[:labels][:traitLines][:hardy]

      assert_includes script[:labels][:super], 'Супер'
      assert_includes hardy, 'шкоди'
      assert_match(/%\{name\}/, hardy)
    end
  end
end
