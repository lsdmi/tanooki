# frozen_string_literal: true

module Pokemons
  module Engine
    # Version 1 rules. The rosters (see Roster) fight in order: a round compares strength x type multiplier /
    # tiredness; the loser faints, the winner stays and tires. Both gain experience every round. All randomness comes
    # from +rng+, in a fixed order.
    class Simulator
      VERSION = 1
      SIDES = %i[attacker defender].freeze

      def self.call(attacker:, defender:, rng:, balance: BattleBalance::V1)
        new(attacker:, defender:, rng:, balance:).call
      end

      def initialize(attacker:, defender:, rng:, balance:)
        @balance = balance
        @teams = Roster.call({ attacker:, defender: }, rng:, team_size: balance.team_size)
        @events = []
        @starting_experience = [attacker, defender].flat_map(&:combatants).to_h { |c| [c.id, c.battle_experience] }
        @experience = @starting_experience.dup
      end

      def call
        round = 0
        fight_round(round += 1) while SIDES.all? { |side| active(side) }
        winner = active(:attacker) ? :attacker : :defender
        emit(:battle_won, round, side: winner)
        Result.new(engine_version: VERSION, winner:, events: @events, experience: changed_experience)
      end

      private

      attr_reader :balance

      def active(side)
        @teams[side].find(&:active)
      end

      def fight_round(round)
        attacker = active(:attacker)
        defender = active(:defender)
        emit(:round_started, round, attacker: attacker.id, defender: defender.id)
        attacker, defender = with_types(*round_traits(attacker, defender, round))
        emit(:round_resolved, round, attacker_score: attacker.score, defender_score: defender.score)
        settle(attacker.score > defender.score ? %i[attacker defender] : %i[defender attacker],
               { attacker:, defender: }, round)
      end

      def round_traits(attacker, defender, round)
        hooks = [[attacker, :attacker], [defender, :defender]].select { |fighter, _| fighter.trait.round_priority }
        hooks.sort_by { |fighter, side| [fighter.trait.round_priority, SIDES.index(side)] }
             .reduce([attacker, defender]) { |pair, (owner, side)| apply_round_trait(pair, owner, side, round) }
      end

      def apply_round_trait(pair, owner, side, round)
        own, opponent = side == :attacker ? pair : pair.reverse
        changed = owner.trait.before_round(own, opponent)
        return pair unless changed

        emit(:trait_triggered, round, combatant: owner.id, trait: owner.trait.key)
        side == :attacker ? changed : changed.reverse
      end

      def with_types(attacker, defender)
        [attacker.with(type: balance.type_chart.multiplier(attacker.types, defender.types)),
         defender.with(type: balance.type_chart.multiplier(defender.types, attacker.types))]
      end

      def settle((winner_side, loser_side), fighters, round)
        winner = fighters[winner_side]
        loser = fighters[loser_side]
        update(loser_side, loser.id) { |fighter| fighter.with(active: false) }
        emit(:fainted, round, combatant: loser.id, side: loser_side)
        tire(winner_side, winner, loser, round)
        gain_experience(fighters[:attacker], fighters[:defender])
      end

      # Added one at a time, in this order (not Array#sum, which compensates rounding), to keep version 1's floats.
      def tire(side, winner, loser, round)
        deltas = [balance.tiredness_for(winner.score - loser.score), *trait_tiredness(winner, loser, round)]
        tired = update(side, winner.id) do |fighter|
          deltas.reduce(fighter) { |total, delta| total.with(tiredness: total.tiredness + delta) }
        end
        emit(:tired, round, combatant: winner.id, tiredness: tired.tiredness)
      end

      def trait_tiredness(winner, loser, round)
        [[winner, winner.trait.after_victory], [loser, loser.trait.after_defeat]].filter_map do |owner, delta|
          emit(:trait_triggered, round, combatant: owner.id, trait: owner.trait.key) if delta
          delta
        end
      end

      # Both gains come from the experience the two had at the start of the round.
      def gain_experience(attacker, defender)
        own = @experience.values_at(attacker.id, defender.id)
        [[attacker, *own], [defender, *own.reverse]].each do |fighter, experience, opponent|
          gain = balance.experience_gain(experience, opponent)
          @experience[fighter.id] = fighter.trait.experience_after(experience, gain, balance.experience_cap)
        end
      end

      def update(side, id)
        team = @teams[side]
        index = team.index { |fighter| fighter.id == id }
        team[index] = yield(team[index])
      end

      def changed_experience
        @experience.reject { |id, experience| experience == @starting_experience[id] }
      end

      def emit(type, round, **data)
        @events << Event.new(type:, round:, data:)
      end
    end
  end
end
