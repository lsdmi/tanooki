# frozen_string_literal: true

class BattleEngine
  include BattleConstants

  def initialize(attacker_team, defender_team, logger)
    @attacker_team_manager = TeamManager.new(attacker_team)
    @defender_team_manager = TeamManager.new(defender_team)
    @logger = logger
  end

  def execute_round
    participants = prepare_battle_participants
    apply_effects_and_types(
      participants[:attacker],
      participants[:defender],
      participants[:attacker_stats],
      participants[:defender_stats]
    )
    attacker_experience = participants[:attacker].battle_experience
    defender_experience = participants[:defender].battle_experience
    process_battle_outcome(participants, attacker_experience, defender_experience)
  end

  def battle_continues?
    @attacker_team_manager.active_pokemon? && @defender_team_manager.active_pokemon?
  end

  def attacker_won?
    @attacker_team_manager.active_pokemon?
  end

  private

  def prepare_battle_participants
    attacker_stats = @attacker_team_manager.find_active_pokemon.dup
    defender_stats = @defender_team_manager.find_active_pokemon.dup
    attacker = UserPokemon.find(attacker_stats[:id])
    defender = UserPokemon.find(defender_stats[:id])
    { attacker: attacker, defender: defender, attacker_stats: attacker_stats, defender_stats: defender_stats }
  end

  def apply_effects_and_types(attacker, defender, attacker_stats, defender_stats)
    apply_character_effects(attacker, defender, attacker_stats, defender_stats)
    calculate_type_effectiveness(attacker_stats, attacker.pokemon, defender.pokemon)
    calculate_type_effectiveness(defender_stats, defender.pokemon, attacker.pokemon)
  end

  def apply_character_effects(attacker, defender, attacker_stats, defender_stats)
    BattleCharacterEffects.apply(attacker, defender, attacker_stats, defender_stats)
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
    BattleCharacterEffects.apply_victory(winner, loser, @attacker_team_manager)
  end

  def update_experience(attacker, defender, attacker_experience, defender_experience)
    ExperienceUpdater.new(attacker, defender, attacker_experience, defender_experience).update
  end

  def calculate_battle_result(stats)
    stats[:raw_total] * stats[:type] / stats[:tiredness]
  end

  def calculate_type_effectiveness(stats, own_pokemon, opponent_pokemon)
    BattleTypeEffectiveness.calculate(stats, own_pokemon, opponent_pokemon)
  end

  def tiredness_stat(attacker, defender)
    BattleTiredness.calculate(
      calculate_battle_result(attacker),
      calculate_battle_result(defender)
    )
  end

  def process_battle_outcome(participants, attacker_experience, defender_experience)
    handle_battle_result(participants)
    update_experience(
      participants[:attacker], participants[:defender],
      attacker_experience, defender_experience
    )
  end

  def handle_battle_result(participants)
    if calculate_battle_result(participants[:attacker_stats]) > calculate_battle_result(participants[:defender_stats])
      handle_battle_victory(participants)
    else
      handle_battle_defeat(participants)
    end
  end

  def handle_battle_victory(participants)
    handle_victory(
      participants[:attacker], participants[:defender],
      participants[:attacker_stats], participants[:defender_stats]
    )
  end

  def handle_battle_defeat(participants)
    handle_defeat(
      participants[:attacker], participants[:defender],
      participants[:attacker_stats], participants[:defender_stats]
    )
  end
end
