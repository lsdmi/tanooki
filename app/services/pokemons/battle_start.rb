# frozen_string_literal: true

module Pokemons
  # One PvP battle against the attacker's pinned opponent. Simulated first; then experience, the battle row, ratings,
  # both battle clocks, and the pin release commit together.
  class BattleStart
    def initialize(attacker)
      @attacker = attacker
    end

    # Returns :fought, :no_opponent, or :cooldown.
    def call
      defender = Matchmaker.new(@attacker).pinned_opponent
      return :no_opponent unless defender

      ApplicationRecord.transaction do
        lock_profiles(@attacker, defender)
        BattleLeaderboardCooldown.call(@attacker) ? :cooldown : fight(defender)
      end
    end

    private

    # Id order keeps two battles between the same pair from deadlocking; reloading under the lock lets the cooldown
    # check stop a second tab from fighting again before the first battle commits.
    def lock_profiles(*users)
      users.sort_by(&:id).each { |user| user.trainer_profile.lock! }
    end

    def fight(defender)
      teams = BattleTeams.new(@attacker, defender)
      seed = PokemonBattle.new_seed
      result = Engine.simulate(attacker: teams.snapshot(:attacker), defender: teams.snapshot(:defender), seed:)
      teams.save_experience(result.experience)
      battle = PokemonBattle.record!(teams:, seed:, result:, rating_deltas: update_ratings(result, defender))
      [@attacker, defender].each { |user| user.trainer_profile.update!(last_battle_at: battle.created_at) }
      Matchmaker.new(@attacker).release!
      :fought
    end

    def update_ratings(result, defender)
      winner, loser = result.attacker_won? ? [@attacker, defender] : [defender, @attacker]
      Battle::RatingUpdater.new(winner: winner.trainer_profile, loser: loser.trainer_profile).call
    end
  end
end
