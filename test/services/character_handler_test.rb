# frozen_string_literal: true

require 'test_helper'

class CharacterHandlerTest < ActiveSupport::TestCase
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

  test 'should handle ambitious character correctly' do
    opponent = Character.new('lucky', 0)
    CharacterHandler.handle_ambitious_character(@attacker, opponent)
    assert_equal 1.0, @attacker[:luck]
    assert_equal 10, @attacker[:raw_total]

    opponent.character = 'unlucky'
    CharacterHandler.handle_ambitious_character(@attacker, opponent)
    assert_equal 0.9, @attacker[:luck]
    assert_equal 9, @attacker[:raw_total]
  end

  test 'should handle prideful character correctly' do
    CharacterHandler.handle_prideful_character(@attacker)
    assert_equal (10 / 1.2), @attacker[:power]
    assert_equal (@attacker[:power] + @attacker[:experience]) * @attacker[:luck], @attacker[:raw_total]
  end

  test 'should handle patient character correctly' do
    CharacterHandler.handle_patient_character(@attacker, @defender)
    assert_equal 1, @defender[:type]

    @attacker[:type] = 3
    @defender[:type] = 2
    CharacterHandler.handle_patient_character(@attacker, @defender)
    assert_equal 2, @defender[:type]
  end

  test 'should handle decisive character correctly' do
    CharacterHandler.handle_decisive_character(@attacker, @defender)
    assert_equal 1, @attacker[:type]

    @attacker[:type] = 2
    @defender[:type] = 1
    CharacterHandler.handle_decisive_character(@attacker, @defender)
    assert_equal 2.1, @attacker[:type]
  end

  test 'should handle hardy character correctly' do
    CharacterHandler.handle_hardy_character(@team, @team.first)
    assert_equal 0.4, @team.first[:tiredness]
  end

  test 'should handle persistent character correctly' do
    CharacterHandler.handle_persistent_character(@character, 100)
    assert_equal 2, @character.battle_experience

    CharacterHandler.handle_persistent_character(@character, 120)
    assert_equal 2, @character.battle_experience
  end
end
