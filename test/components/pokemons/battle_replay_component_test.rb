# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleReplayComponentTest < ViewComponentTestCase
    include PokemonBattleHelpers

    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      UserPokemon.create!(user: @attacker, pokemon: pokemons(:four), character: :brave, battle_experience: 40)
      UserPokemon.create!(user: @defender, pokemon: pokemons(:five), character: :hardy, battle_experience: 10)
    end

    test 'wires the battle-replay stage controls' do
      render_inline(BattleReplayComponent.new(battle: fought_battle))

      assert_selector '[data-controller="battle-replay"]'
      assert_selector '[data-battle-replay-target="stepBack"]'
      assert_selector '[data-battle-replay-target="stepForward"]'
    end

    test 'exposes play skip and speed on the stage' do
      render_inline(BattleReplayComponent.new(battle: fought_battle))

      assert_selector '[data-battle-replay-target="play"]', text: I18n.t('pokemons.battle.replay.play')
      assert_selector 'button[data-action="battle-replay#skip"]', text: I18n.t('pokemons.battle.replay.skip')
      assert_selector '[data-battle-replay-target="speed"]'
    end

    test 'labels attack and defense sides with a finished header' do
      battle = fought_battle

      render_inline(BattleReplayComponent.new(battle:))

      assert_text I18n.t('pokemons.teams.attack')
      assert_text I18n.t('pokemons.teams.defense')
      assert_selector 'h3', text: I18n.t('pokemons.battle.finished', count: battle.events_of(:round_started).size)
    end

    test 'version 2 battles paint HP meters' do
      render_inline(BattleReplayComponent.new(battle: fought_battle))

      assert_selector '[data-battle-replay-target="attackerHp"]'
      assert_selector '[data-battle-replay-target="defenderHp"]'
    end

    test 'version 2 battles put HP into the replay script' do
      render_inline(BattleReplayComponent.new(battle: fought_battle))

      script = JSON.parse(page.find('[data-controller="battle-replay"]')['data-battle-replay-script-value'])

      assert script['hp']
      assert(script['events'].any? { |event| event['type'] == 'hit' })
      assert(script['fighters'].values.all? { |fighter| fighter['maxHp'].present? })
    end

    test 'folded, the stage waits for the panel to unfold and the result stays' do
      render_inline(BattleReplayComponent.new(battle: fought_battle, folded: true))

      assert_selector '[data-controller="battle-replay"][hidden][data-panel-fold-target=open]', visible: :all
      assert_selector 'h3', text: /\AБій завершено за \d+ раунд/
    end

    test 'names the winner and the loser' do
      battle = fought_battle
      winner, loser = battle.attacker_won? ? [@attacker, @defender] : [@defender, @attacker]

      render_inline(BattleReplayComponent.new(battle:))

      assert_selector 'h3 + p span', text: loser.name
      assert_selector 'h3 + p span', text: winner.name
    end

    test 'a legacy battle shows the header and the result without the stage' do
      battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @defender,
                                     engine_version: PokemonBattle::LEGACY_VERSION)

      render_inline(BattleReplayComponent.new(battle:))

      assert_text 'Раунди цього бою не збереглися'
      assert_no_selector '[data-controller="battle-replay"]'
      assert_selector 'h3 + p span.text-status-danger-solid', text: @attacker.name
    end

    test 'a legacy battle names no round count' do
      battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @defender,
                                     engine_version: PokemonBattle::LEGACY_VERSION)

      render_inline(BattleReplayComponent.new(battle:))

      assert_selector 'h3', exact_text: 'Бій завершено!'
    end

    test 'a new battle has no legacy note' do
      render_inline(BattleReplayComponent.new(battle: fought_battle))

      assert_no_text 'Раунди цього бою не збереглися'
    end

    private

    def fought_battle
      Matchmaker.new(@attacker).opponent
      BattleStart.new(@attacker).call
      PokemonBattle.last
    end
  end
end
