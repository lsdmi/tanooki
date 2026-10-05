# frozen_string_literal: true

module Pokemons
  module Engine
    # One version 2 hit. Draws the roll (a second, strong one for a lucky striker's weak roll), the crit, then (only
    # against an agile target) the dodge, so the draws follow from the two Pokémon and never from their sides. Applies
    # both Pokémon's traits (HpTraits); +triggers+ lists [combatant id, trait] for each trait that changed the hit, in
    # the order they acted.
    class HpStrike
      Outcome = Data.define(:striker, :target, :damage, :crit, :dodged, :effect, :triggers)

      def self.call(...)
        new(...).call
      end

      def initialize(striker:, target:, opening:, rng:, balance:)
        @striker = striker
        @target = target
        @opening = opening
        @rng = rng
        @balance = balance
        @triggers = []
      end

      def call
        roll = draw_roll
        crit = crit?
        return dodge if dodged?

        damage = attack * roll * (crit ? @balance.crit_multiplier : 1) * opening
        outcome(guarded(damage), crit:, effect:)
      end

      private

      def draw_roll
        first = @rng.rand(@balance.roll_range)
        return first unless HpTraits.reroll?(@striker, first)

        trigger(@striker, 'lucky')
        @rng.rand(HpTraits::LUCKY_BELOW..@balance.roll_range.end)
      end

      def crit?
        draw = @rng.rand
        trigger(@striker, 'decisive') if draw >= @balance.crit_chance && draw < HpTraits.crit_chance(@striker, @balance)
        draw < HpTraits.crit_chance(@striker, @balance)
      end

      def dodged?
        chance = HpTraits.dodge_chance(@target)
        chance.positive? && @rng.rand < chance
      end

      # Nothing the striker drew lands, so the dodge is the only trigger.
      def dodge
        @triggers = [[@target.id, 'agile']]
        outcome(0.0, crit: false, effect: nil, dodged: true)
      end

      # How the raw type chart rates the hit, for the replay: 'super', 'weak', or nil when neutral.
      def effect
        multiplier = @balance.type_chart.multiplier(@striker.types, @target.types)
        if multiplier > 1 then 'super'
        elsif multiplier < 1 then 'weak'
        end
      end

      def attack
        bonus = HpTraits.attack_bonus(@striker, @target)
        trigger(@striker, @striker.character) if bonus
        @striker.attack * type_multiplier * (bonus || 1)
      end

      def type_multiplier
        @balance.type_multiplier(@striker.types, @target.types)
      end

      def opening
        return 1 unless @opening

        trigger(@striker, 'independent') if @striker.character == 'independent'
        HpTraits.opening_hit(@striker, @balance)
      end

      def guarded(damage)
        guard = HpTraits.guard(@target)
        trigger(@target, 'hardy') if guard
        damage * (guard || 1)
      end

      def outcome(damage, crit:, effect:, dodged: false)
        survives = HpTraits.survives?(@target, damage)
        trigger(@target, 'persistent') if survives
        hp = survives ? [@target.hp, 1.0].min : [@target.hp - damage, 0.0].max
        target = @target.with(hp:, wounded: @target.wounded || damage.positive?, survived: @target.survived || survives)
        striker = @striker.with(countered: @striker.countered || patient_countered?)
        Outcome.new(striker:, target:, damage:, crit:, dodged:, effect:, triggers: @triggers)
      end

      def patient_countered?
        @triggers.include?([@striker.id, 'patient'])
      end

      def trigger(fighter, trait)
        @triggers << [fighter.id, trait]
      end
    end
  end
end
