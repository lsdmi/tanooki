# frozen_string_literal: true

module Pokemons
  module Engine
    # The numbers version 2 runs on. Species stats are pulled towards the mean (stat_exponent), so the species
    # matters without deciding every battle; experience is the only thing a trainer grows (level only drives
    # evolution). Damage is scaled so an average Pokémon faints in about +hits_to_faint+ hits.
    HpBalance = Data.define(:team_size, :stat_exponent, :mean_hp, :mean_attack, :experience_bonus, :hits_to_faint,
                            :roll_range, :crit_chance, :crit_multiplier, :type_exponent, :opening_hit,
                            :experience_steps, :experience_cap, :type_chart) do
      def hp(combatant)
        stat(combatant.base_hp, mean_hp) * experience_factor(combatant.battle_experience)
      end

      # Damage of a plain hit before the type multiplier and the roll.
      def attack(combatant)
        stat(combatant.base_attack, mean_attack) * damage_scale * experience_factor(combatant.battle_experience)
      end

      # Softens a type chart multiplier.
      def soften(multiplier)
        multiplier**type_exponent
      end

      def type_multiplier(own_types, opponent_types)
        soften(type_chart.multiplier(own_types, opponent_types))
      end

      # By how close the opponent's experience is to its own (version 2 gives half of version 1's gains).
      def experience_gain(own, opponent)
        experience_steps.find { |window, _| own - window < opponent }&.last || 0
      end

      private

      def stat(base, mean)
        mean * (base.fdiv(mean)**stat_exponent)
      end

      def experience_factor(experience)
        1 + (experience_bonus * [experience, experience_cap].min.fdiv(experience_cap))
      end

      def damage_scale
        mean_hp / (mean_attack * hits_to_faint * average_roll * average_crit)
      end

      def average_roll
        (roll_range.begin + roll_range.end) / 2.0
      end

      def average_crit
        1 + (crit_chance * (crit_multiplier - 1))
      end
    end

    HpBalance::V2 = HpBalance.new(
      team_size: 6,
      stat_exponent: 0.2,
      mean_hp: BaseStats.mean(:hp),
      mean_attack: BaseStats.mean(:attack),
      experience_bonus: 0.2,
      hits_to_faint: 2,
      roll_range: 0.7..1.0,
      crit_chance: 0.125,
      crit_multiplier: 2,
      type_exponent: 0.45,
      opening_hit: 0.4,
      experience_steps: [[15, 1]].freeze,
      experience_cap: 100,
      type_chart: TypeChart.default
    )
  end
end
