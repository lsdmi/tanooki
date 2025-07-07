# frozen_string_literal: true

class BattleCharacterEffects
  def self.apply(attacker, defender, attacker_stats, defender_stats)
    CharacterEffectApplier.new(attacker, defender, attacker_stats, defender_stats).apply
  end

  def self.apply_victory(winner, loser, attacker_team_manager)
    if winner.character == 'hardy'
      CharacterHandler.handle_hardy_character(attacker_team_manager.team, { id: winner.id })
    end
    return unless loser.character == 'agile'

    CharacterHandler.handle_agile_character(attacker_team_manager.team, { id: winner.id })
  end
end
