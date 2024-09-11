# frozen_string_literal: true

module CharacterHandler
  def self.handle_friendly_character(attacker, defender)
    [attacker, defender].each do |character_stats|
      character_stats[:experience] = 1
      character_stats[:raw_total] = raw_strength_formula(character_stats[:power], character_stats[:luck])
    end
  end

  def self.handle_ambitious_character(stats, opponent)
    stats[:luck] = opponent.character == 'lucky' ? 1.0 : 0.9
    stats[:raw_total] = raw_strength_formula(stats[:power], stats[:luck], stats[:experience])
  end

  def self.handle_prideful_character(stats)
    stats[:power] = stats[:power] / 1.2
    stats[:raw_total] = raw_strength_formula(stats[:power], stats[:luck], stats[:experience])
  end

  def self.handle_patient_character(attacker_stats, defender_stats)
    defender_stats[:type] = attacker_stats[:type] if attacker_stats[:type] < defender_stats[:type]
  end

  def self.handle_decisive_character(attacker_stats, defender_stats)
    attacker_stats[:type] += 0.1 if attacker_stats[:type] > defender_stats[:type]
  end

  def self.handle_hardy_character(team, stats)
    selected = team.find { |pokemon| pokemon[:id] == stats[:id] }
    selected[:tiredness] -= 0.1
  end

  def self.handle_agile_character(team, stats)
    selected = team.find { |pokemon| pokemon[:id] == stats[:id] }
    selected[:tiredness] += 0.1
  end

  def self.handle_persistent_character(character, experience)
    character.update(battle_experience: character.battle_experience + 1) if experience < 115
  end

  def self.raw_strength_formula(power, luck, experience = 0)
    (power + experience) * luck
  end
end
