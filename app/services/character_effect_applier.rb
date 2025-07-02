# frozen_string_literal: true

class CharacterEffectApplier
  def initialize(attacker, defender, attacker_stats, defender_stats)
    @attacker = attacker
    @defender = defender
    @attacker_stats = attacker_stats
    @defender_stats = defender_stats
  end

  def apply
    apply_friendly_character_effects
    apply_ambitious_character_effects
    apply_prideful_character_effects
    apply_patient_character_effects
    apply_decisive_character_effects
  end

  private

  def apply_friendly_character_effects
    return unless [@attacker.character, @defender.character].include?('friendly')

    CharacterHandler.handle_friendly_character(@attacker_stats, @defender_stats)
  end

  def apply_ambitious_character_effects
    CharacterHandler.handle_ambitious_character(@defender_stats, @defender) if @attacker.character == 'ambitious'
    CharacterHandler.handle_ambitious_character(@attacker_stats, @attacker) if @defender.character == 'ambitious'
  end

  def apply_prideful_character_effects
    CharacterHandler.handle_prideful_character(@defender_stats) if @attacker.character == 'prideful'
    CharacterHandler.handle_prideful_character(@attacker_stats) if @defender.character == 'prideful'
  end

  def apply_patient_character_effects
    CharacterHandler.handle_patient_character(@attacker_stats, @defender_stats) if @attacker.character == 'patient'
    CharacterHandler.handle_patient_character(@defender_stats, @attacker_stats) if @defender.character == 'patient'
  end

  def apply_decisive_character_effects
    CharacterHandler.handle_decisive_character(@attacker_stats, @defender_stats) if @attacker.character == 'decisive'
    CharacterHandler.handle_decisive_character(@defender_stats, @attacker_stats) if @defender.character == 'decisive'
  end
end
