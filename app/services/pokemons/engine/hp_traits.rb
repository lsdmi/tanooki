# frozen_string_literal: true

module Pokemons
  module Engine
    # Version 2 trait effects: each trait does one small thing inside the fight. Version 1 keeps Traits, so its
    # battles replay unchanged.
    # Each effect is tuned so a team with the trait beats the same lineup without traits about two times in three.
    # - agile: dodges a hit now and then
    # - ambitious: hits harder while it has less HP left than its opponent; prideful: while it has more
    # - brave: hits harder below half HP; confident: at half HP or above
    # - decisive: crits more often; lucky: rerolls a weak roll into a strong one
    # - hardy: takes less damage below half HP
    # - patient: its first hit after taking one in a round is stronger
    # - persistent: once per battle, a lethal hit taken above 45% HP leaves it at 1 HP
    # - independent: does not hold back its opening hit as much
    # - friendly: gets back part of its HP after winning a round
    module HpTraits
      DODGE = 0.06
      AMBITION = 1.1
      PRIDE = 1.4
      COURAGE = 1.15
      CONFIDENCE = 1.11
      DECISIVE_CRIT = 0.2
      LUCKY_BELOW = 0.8
      HARDY_GUARD = 0.83
      PATIENT_COUNTER = 1.12
      INDEPENDENT_OPENING = 0.55
      FRIENDLY_HEAL = 0.1
      PERSISTENT_ABOVE = 0.45

      # Trait => [damage bonus, when it applies to the striker hitting the target].
      ATTACK_BONUSES = {
        'ambitious' => [AMBITION, ->(striker, target) { striker.hp < target.hp }],
        'prideful' => [PRIDE, ->(striker, target) { striker.hp > target.hp }],
        'brave' => [COURAGE, ->(striker, _) { striker.hp < striker.max_hp / 2 }],
        'confident' => [CONFIDENCE, ->(striker, _) { striker.hp >= striker.max_hp / 2 }],
        'patient' => [PATIENT_COUNTER, ->(striker, _) { striker.wounded && !striker.countered }]
      }.freeze

      # The striker's own damage bonus, or nil when its trait does not apply to this hit.
      def self.attack_bonus(striker, target)
        bonus, applies = ATTACK_BONUSES[striker.character]
        bonus if applies&.call(striker, target)
      end

      def self.opening_hit(striker, balance)
        striker.character == 'independent' ? INDEPENDENT_OPENING : balance.opening_hit
      end

      def self.reroll?(striker, roll)
        striker.character == 'lucky' && roll < LUCKY_BELOW
      end

      # The HP a friendly round winner gets back, or nil.
      def self.recovery(winner)
        return unless winner.character == 'friendly' && winner.hp < winner.max_hp

        [winner.max_hp * FRIENDLY_HEAL, winner.max_hp - winner.hp].min
      end

      def self.crit_chance(striker, balance)
        striker.character == 'decisive' ? DECISIVE_CRIT : balance.crit_chance
      end

      def self.dodge_chance(target)
        target.character == 'agile' ? DODGE : 0
      end

      def self.guard(target)
        HARDY_GUARD if target.character == 'hardy' && target.hp < target.max_hp / 2
      end

      def self.survives?(target, damage)
        target.character == 'persistent' && !target.survived && target.hp > target.max_hp * PERSISTENT_ABOVE &&
          damage >= target.hp
      end
    end
  end
end
