# frozen_string_literal: true

module Pokemons
  # One PvP battle against the attacker's pinned opponent. Simulated first; then experience, the battle row, ratings,
  # and the pin release commit together.
  class BattleStart
    def initialize(attacker)
      @attacker = attacker
    end

    # Returns :fought, :no_opponent, or :cooldown.
    def call
      defender = Matchmaker.new(@attacker).pinned_opponent
      return :no_opponent unless defender

      ApplicationRecord.transaction do
        lock_users(@attacker, defender)
        BattleLeaderboardCooldown.call(@attacker) ? :cooldown : fight(defender)
      end
    end

    private

    # Id order keeps two battles between the same pair from deadlocking; the cooldown check after the lock stops a
    # second tab from fighting again before the first battle commits.
    def lock_users(*users)
      User.where(id: users.map(&:id)).order(:id).lock.pluck(:id)
    end

    def fight(defender)
      teams = BattleTeams.new(@attacker, defender)
      seed = PokemonBattle.new_seed
      result = Engine.simulate(attacker: teams.snapshot(:attacker), defender: teams.snapshot(:defender), seed:)
      teams.save_experience(result.experience)
      PokemonBattle.record!(teams:, seed:, result:, rating_deltas: update_ratings(result, defender))
      Matchmaker.new(@attacker).release!
      :fought
    end

    def update_ratings(result, defender)
      winner, loser = result.attacker_won? ? [@attacker, defender] : [defender, @attacker]
      Battle::RatingUpdater.new(winner_id: winner.id, loser_id: loser.id).call
    end
  end
end
