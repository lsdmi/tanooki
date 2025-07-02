# frozen_string_literal: true

class BattleEngine
  include BattleConstants

  def initialize(attacker_team, defender_team, logger)
    @attacker_team_manager = TeamManager.new(attacker_team)
    @defender_team_manager = TeamManager.new(defender_team)
    @logger = logger
  end

  def execute_round
    attacker_stats = @attacker_team_manager.find_active_pokemon.dup
    defender_stats = @defender_team_manager.find_active_pokemon.dup

    attacker = UserPokemon.find(attacker_stats[:id])
    defender = UserPokemon.find(defender_stats[:id])

    apply_character_effects(attacker, defender, attacker_stats, defender_stats)
    calculate_type_effectiveness(attacker_stats, attacker.pokemon, defender.pokemon)
    calculate_type_effectiveness(defender_stats, defender.pokemon, attacker.pokemon)

    attacker_experience = attacker.battle_experience
    defender_experience = defender.battle_experience

    if calculate_battle_result(attacker_stats) > calculate_battle_result(defender_stats)
      handle_victory(attacker, defender, attacker_stats, defender_stats)
    else
      handle_defeat(attacker, defender, attacker_stats, defender_stats)
    end

    update_experience(attacker, defender, attacker_experience, defender_experience)
  end

  def battle_continues?
    @attacker_team_manager.has_active_pokemon? && @defender_team_manager.has_active_pokemon?
  end

  def attacker_won?
    @attacker_team_manager.has_active_pokemon?
  end

  private

  def apply_character_effects(attacker, defender, attacker_stats, defender_stats)
    CharacterEffectApplier.new(attacker, defender, attacker_stats, defender_stats).apply
  end

  def handle_victory(attacker, defender, attacker_stats, defender_stats)
    @logger.append_outcome(attacker, defender, :victory)
    @defender_team_manager.deactivate_pokemon(defender_stats[:id])
    @attacker_team_manager.add_tiredness(attacker_stats[:id], tiredness_stat(attacker_stats, defender_stats))
    apply_victory_character_effects(attacker, defender)
  end

  def handle_defeat(attacker, defender, attacker_stats, defender_stats)
    @logger.append_outcome(attacker, defender, :defeat)
    @attacker_team_manager.deactivate_pokemon(attacker_stats[:id])
    @defender_team_manager.add_tiredness(defender_stats[:id], tiredness_stat(defender_stats, attacker_stats))
    apply_victory_character_effects(defender, attacker)
  end

  def apply_victory_character_effects(winner, loser)
    if winner.character == 'hardy'
      CharacterHandler.handle_hardy_character(@attacker_team_manager.team, { id: winner.id })
    end
    return unless loser.character == 'agile'

    CharacterHandler.handle_agile_character(@attacker_team_manager.team, { id: winner.id })
  end

  def update_experience(attacker, defender, attacker_experience, defender_experience)
    ExperienceUpdater.new(attacker, defender, attacker_experience, defender_experience).update
  end

  def calculate_battle_result(stats)
    stats[:raw_total] * stats[:type] / stats[:tiredness]
  end

  def calculate_type_effectiveness(stats, own_pokemon, opponent_pokemon)
    effectiveness = 1.0

    own_pokemon.types.each do |attacker_type|
      opponent_pokemon.types.each do |defender_type|
        effectiveness *= TypeAdvantage.effectiveness(attacker_type.name, defender_type.name)
      end
    end

    stats[:type] = effectiveness
  end

  def tiredness_stat(attacker, defender)
    difference = calculate_battle_result(attacker) - calculate_battle_result(defender)

    case difference
    when TIREDNESS_THRESHOLDS[:overwhelming_victory]..Float::INFINITY
      TIREDNESS_VALUES[:overwhelming_victory]
    when TIREDNESS_THRESHOLDS[:significant_victory]..TIREDNESS_THRESHOLDS[:overwhelming_victory]
      TIREDNESS_VALUES[:significant_victory]
    else
      TIREDNESS_VALUES[:close_victory]
    end
  end
end
