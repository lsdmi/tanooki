# frozen_string_literal: true

module Pokemons
  # One PvP battle against the attacker's pinned opponent. Experience, log, ratings, and pin release commit together.
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
      run = run_battle(defender)
      PokemonBattleLog.create!(attacker_id: @attacker.id, defender_id: defender.id, winner_id: run.winner_id,
                               details: run.fight_details)
      Battle::RatingUpdater.new(winner_id: run.winner_id, loser_id: run.loser_id).call
      Matchmaker.new(@attacker).release!
      :fought
    end

    def run_battle(defender)
      BattleRun.new(attacker_pokemons: @attacker.user_pokemons, defender_pokemons: defender.user_pokemons,
                    attacker_id: @attacker.id, defender_id: defender.id).tap(&:start_battle)
    end
  end
end
