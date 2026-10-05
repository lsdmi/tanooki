# frozen_string_literal: true

require 'test_helper'

class PokemonBattleTest < ActiveSupport::TestCase
  include PokemonBattleHelpers

  TEAM = [{ 'id' => 7, 'character' => 'lucky', 'power_level' => 3, 'battle_experience' => 20, 'types' => %w[Водяний],
            'pokemon_id' => 1 }].freeze

  setup do
    @attacker = users(:user_one)
    @defender = users(:user_two)
  end

  test 'rebuilds the engine snapshot from the stored team' do
    battle = create_pokemon_battle(attacker: @attacker, defender: @defender, attacker_team: TEAM)
    combatant = battle.reload.snapshot(:attacker).combatants.sole

    assert_equal [7, 'lucky', 3, 20, %w[Водяний], nil, nil], combatant.to_h.values
    assert_equal @attacker.id, battle.snapshot(:attacker).trainer_id
  end

  test 'a version 2 battle replays from its stored teams and keeps its hits through MySQL' do
    team = [TEAM.first.merge('base_hp' => 160, 'base_attack' => 110)]
    result = Pokemons::Engine.simulate(attacker: snapshot(team), defender: snapshot(team, id: 8), seed: 4, version: 2)
    battle = create_pokemon_battle(attacker: @attacker, defender: @defender, engine_version: 2, seed: 4,
                                   attacker_team: team, defender_team: [team.first.merge('id' => 8)],
                                   events: PokemonBattle.serialize(result.events))

    assert_equal result, battle.reload.replay
    assert_equal PokemonBattle.serialize(result.events), battle.events
    assert_not_empty battle.events_of(:hit)
  end

  test 'stored version 1 events come back from MySQL unchanged' do
    (1..20).each do |seed|
      result = Pokemons::Engine.simulate(attacker: snapshot(TEAM), defender: snapshot(TEAM, id: 8), seed:, version: 1)
      events = PokemonBattle.serialize(result.events)

      assert_equal events, create_pokemon_battle(attacker: @attacker, defender: @defender, events:).reload.events
    end
  end

  test 'stored scores are rounded to four decimals' do
    event = Pokemons::Engine::Event.new(type: :round_resolved, round: 1,
                                        data: { attacker_score: 437.38623845712027, defender_score: 2 })

    expected = { 'type' => 'round_resolved', 'round' => 1,
                 'data' => { 'attacker_score' => 437.3862, 'defender_score' => 2 } }

    assert_equal [expected], PokemonBattle.serialize([event])
  end

  test 'involving finds battles on either side' do
    as_attacker = create_pokemon_battle(attacker: @attacker, defender: @defender)
    as_defender = create_pokemon_battle(attacker: @defender, defender: @attacker, winner: @defender)

    assert_equal [as_attacker, as_defender], PokemonBattle.involving(@attacker).order(:id).to_a
    assert_empty PokemonBattle.involving(User.find(101))
  end

  test 'seeds fit the column' do
    assert(Array.new(20) { PokemonBattle.new_seed }.all? { |seed| seed.between?(0, (2**63) - 1) })
  end

  test 'an unknown engine version does not replay' do
    battle = create_pokemon_battle(attacker: @attacker, defender: @defender, engine_version: 99)

    assert_raises(ArgumentError) { battle.replay }
  end

  private

  def snapshot(team, id: nil)
    combatants = team.map do |entry|
      Pokemons::Engine::Combatant.new(**entry.symbolize_keys.except(:pokemon_id), id: id || entry['id'])
    end
    Pokemons::Engine::TeamSnapshot.new(trainer_id: 1, combatants:)
  end
end
