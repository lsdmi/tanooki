# frozen_string_literal: true

module Pokemons
  module Engine
    # Version 2 rules: HP and turns. Each side fields its strongest Pokémon by HP x attack, up to the smaller team and
    # the team size. In a round a seeded coin picks who strikes first, then the two alternate until one reaches 0 HP;
    # the opening hit is weaker, so striking first is a small edge. Each hit is an HpStrike, with both Pokémon's
    # traits. The loser faints, the winner keeps its HP for the next round (a friendly one gets some back). Both gain
    # experience every round.
    #
    # Every roll depends on the two Pokémon in the round, never on their sides, so swapping sides with the same seed
    # mirrors the battle.
    class HpSimulator
      VERSION = 2
      SIDES = %i[attacker defender].freeze

      class MissingStats < ArgumentError; end

      def self.call(attacker:, defender:, rng:, balance: HpBalance::V2)
        new(attacker:, defender:, rng:, balance:).call
      end

      def initialize(attacker:, defender:, rng:, balance:)
        @rng = rng
        @balance = balance
        @teams = roster({ attacker:, defender: })
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

      attr_reader :balance, :rng

      def roster(snapshots)
        limit = [balance.team_size, *snapshots.values.map { |snapshot| snapshot.combatants.size }].min
        snapshots.transform_values { |snapshot| strongest(snapshot, limit) }
      end

      def strongest(snapshot, limit)
        snapshot.combatants.map { |combatant| fighter(combatant) }.sort_by { |f| [-f.power, f.id] }.first(limit)
      end

      def fighter(combatant)
        unless combatant.base_hp && combatant.base_attack
          raise MissingStats, "Combatant #{combatant.id} has no base stats"
        end

        hp = balance.hp(combatant)
        HpFighter.new(id: combatant.id, character: combatant.character, types: combatant.types, max_hp: hp, hp:,
                      attack: balance.attack(combatant), wounded: false, countered: false, survived: false)
      end

      def active(side)
        @teams[side].first
      end

      def fight_round(round)
        SIDES.each { |side| @teams[side][0] = active(side).with(wounded: false, countered: false) }
        ids = SIDES.index_with { |side| active(side).id }
        order = strike_order(ids)
        emit(:round_started, round, **ids, first_striker: ids[order.first])
        exchange(order, round)
        settle(order.last, ids, round)
      end

      # The coin picks one of the two Pokémon by id, so swapping sides does not change who starts.
      def strike_order(ids)
        lower, higher = SIDES.sort_by { |side| ids[side] }
        rng.rand(2).zero? ? [lower, higher] : [higher, lower]
      end

      # Hits alternate until one falls; leaves +order+ with the winner first.
      def exchange(order, round)
        opening = true
        until strike(*order, opening:, round:).zero?
          order.reverse!
          opening = false
        end
      end

      # Returns the target's HP after the hit.
      def strike(striker_side, target_side, opening:, round:)
        outcome = HpStrike.call(striker: active(striker_side), target: active(target_side), opening:, rng:, balance:)
        @teams[striker_side][0] = outcome.striker
        @teams[target_side][0] = outcome.target
        record(outcome, round)
        outcome.target.hp
      end

      def record(outcome, round)
        outcome.triggers.each { |id, trait| emit(:trait_triggered, round, combatant: id, trait:) }
        emit(:hit, round, striker: outcome.striker.id, target: outcome.target.id, damage: outcome.damage,
                          hp_left: outcome.target.hp, **outcome.to_h.slice(:crit, :dodged, :effect))
      end

      def settle(loser_side, ids, round)
        loser = @teams[loser_side].shift
        emit(:fainted, round, combatant: loser.id, side: loser_side)
        recover((SIDES - [loser_side]).first, round)
        gain_experience(ids)
      end

      def recover(winner_side, round)
        winner = active(winner_side)
        amount = HpTraits.recovery(winner)
        return unless amount

        @teams[winner_side][0] = winner.with(hp: winner.hp + amount)
        emit(:trait_triggered, round, combatant: winner.id, trait: winner.character)
        emit(:healed, round, combatant: winner.id, amount:, hp_left: winner.hp + amount)
      end

      # Both gains come from the experience the two had at the start of the round.
      def gain_experience(ids)
        own = @experience.values_at(ids[:attacker], ids[:defender])
        [[ids[:attacker], *own], [ids[:defender], *own.reverse]].each do |id, experience, opponent|
          gain = balance.experience_gain(experience, opponent)
          @experience[id] = Traits::BASE.experience_after(experience, gain, balance.experience_cap)
        end
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
