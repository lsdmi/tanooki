# frozen_string_literal: true

module Pokemons
  module Engine
    # Turns both snapshots into fighters and keeps each side's strongest by rolled strength, up to the smaller team
    # and the team size. Luck is rolled for the attacker's team first, each team in snapshot order.
    module Roster
      def self.call(snapshots, rng:, team_size:)
        limit = [team_size, *snapshots.values.map { |snapshot| snapshot.combatants.size }].min
        snapshots.transform_values do |snapshot|
          snapshot.combatants.map { |combatant| fighter(combatant, rng) }.sort_by { |f| -f.raw_total }.first(limit)
        end
      end

      def self.fighter(combatant, rng)
        trait = Traits.for(combatant.character)
        power = combatant.power_level * trait.power_multiplier
        experience = combatant.battle_experience * trait.experience_multiplier
        Fighter.new(id: combatant.id, character: combatant.character, types: combatant.types, power:, experience:,
                    type: 1, tiredness: 1, active: true, **luck_rolls(trait, power, experience, rng))
      end

      # Luck is rolled twice: once for the stored luck (used by round traits), then once inside the starting strength.
      def self.luck_rolls(trait, power, experience, rng)
        luck = rng.rand(trait.luck_range)
        { luck:, raw_total: Fighter.strength(power, rng.rand(trait.luck_range), experience) }
      end
    end
  end
end
