# frozen_string_literal: true

module Pokemons
  # One PvP battle against the attacker's pinned opponent. Simulated first; then experience, the battle row, ratings
  # (none for a rematch within a day), both battle clocks, and the pin release commit together.
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
      ActiveRecord::Associations::Preloader.new(records: users, associations: :trainer_profile).call
      users.sort_by(&:id).each { |user| user.trainer_profile.lock! }
    end

    def fight(defender)
      teams = BattleTeams.new(@attacker, defender, attacker_attack_bonus: x_attack_bonus)
      seed = PokemonBattle.new_seed
      result = Engine.simulate(attacker: teams.snapshot(:attacker), defender: teams.snapshot(:defender), seed:)
      persist_fight!(teams, seed, result, defender)
      :fought
    end

    def persist_fight!(teams, seed, result, defender)
      teams.save_experience(result.experience)
      battle = PokemonBattle.record!(teams:, seed:, result:, rating_deltas: update_ratings(result, defender))
      [@attacker, defender].each { |user| user.trainer_profile.update!(last_battle_at: battle.created_at) }
      Matchmaker.new(@attacker).release!
      record_quest_win(result, teams, defender, battle)
    end

    def x_attack_bonus
      profile = @attacker.trainer_profile
      return 1.0 unless profile.item_effect('x_attack')

      profile.write_item_effect!('x_attack', nil)
      1.2
    end

    def record_quest_win(result, teams, defender, battle)
      winner = result.attacker_won? ? @attacker : defender
      roster = result.attacker_won? ? :attacker : :defender
      side = result.attacker_won? ? :attack : :defense
      types = teams.snapshot(roster).combatants.flat_map(&:types).uniq
      DailyQuests::Progress.call(winner, event: :battle_win, types:, ranked: battle.ranked?, side:)
    end

    # nil for a rematch inside Balance::RANKED_REMATCH_GAP: it plays unranked.
    def update_ratings(result, defender)
      return if PokemonBattle.rematch?(@attacker, defender)

      winner, loser = result.attacker_won? ? [@attacker, defender] : [defender, @attacker]
      Battle::RatingUpdater.new(winner: winner.trainer_profile, loser: loser.trainer_profile).call
    end
  end
end
