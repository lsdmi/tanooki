# frozen_string_literal: true

require 'test_helper'

module Pokemons
  class BattleReplayComponentTest < ViewComponentTestCase
    include PokemonBattleHelpers

    setup do
      @attacker = users(:user_one)
      @defender = users(:user_two)
      UserPokemon.create!(user: @attacker, pokemon: pokemons(:two), character: :brave, battle_experience: 40)
      UserPokemon.create!(user: @defender, pokemon: pokemons(:three), character: :hardy, battle_experience: 10)
    end

    test 'one card per round with both species, then the result' do
      battle = fought_battle
      rounds = battle.events_of(:round_started).size

      render_inline(BattleReplayComponent.new(battle:))

      assert_selector 'h1', text: 'Вітаємо на Арені!'
      assert_selector 'span', text: "Раунд #{rounds}"
      assert_selector 'h2', text: 'Бій завершено!'
    end

    test 'shows the species each Pokémon fought as, even after it evolved' do
      battle = fought_battle
      species = fought_species(battle)
      UserPokemon.find_each { |user_pokemon| user_pokemon.update!(pokemon: pokemons(:three)) }

      render_inline(BattleReplayComponent.new(battle:))

      assert_includes species, pokemons(:one).name
      assert_equal species, page.all('img').pluck(:alt).uniq.sort
    end

    test 'names the winner and the loser' do
      battle = fought_battle
      winner, loser = battle.attacker_won? ? [@attacker, @defender] : [@defender, @attacker]

      render_inline(BattleReplayComponent.new(battle:))

      assert_selector 'h2 + p span', text: loser.name
      assert_selector 'h2 + p span', text: winner.name
    end

    test 'a species deleted since the battle leaves an empty ring' do
      battle = create_pokemon_battle(
        attacker: @attacker, defender: @defender,
        attacker_team: [{ 'id' => 1, 'pokemon_id' => 0 }], defender_team: [{ 'id' => 2, 'pokemon_id' => 0 }],
        events: [{ 'type' => 'round_started', 'round' => 1, 'data' => { 'attacker' => 1, 'defender' => 2 } },
                 { 'type' => 'fainted', 'round' => 1, 'data' => { 'combatant' => 2, 'side' => 'defender' } }]
      )

      render_inline(BattleReplayComponent.new(battle:))

      assert_selector 'span', text: 'Раунд 1'
      assert_no_selector 'img'
    end

    test 'a legacy battle shows the header and the result without rounds' do
      battle = create_pokemon_battle(attacker: @attacker, defender: @defender, winner: @defender,
                                     engine_version: PokemonBattle::LEGACY_VERSION)

      render_inline(BattleReplayComponent.new(battle:))

      assert_text 'Раунди цього бою не збереглися'
      assert_no_selector 'span', text: 'Раунд'
      assert_selector 'h2 + p span.text-status-danger-solid', text: @attacker.name
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

    def fought_species(battle)
      pokemon_ids = (battle.attacker_team + battle.defender_team).to_h { |entry| entry.values_at('id', 'pokemon_id') }
      ids = battle.events_of(:round_started).flat_map { |event| event['data'].values_at('attacker', 'defender') }
      Pokemon.where(id: pokemon_ids.values_at(*ids)).pluck(:name).sort
    end
  end
end
