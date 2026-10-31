# frozen_string_literal: true

module Pokemons
  # Read-model for the Studio "Pokémons" tab: party list, dex ranks, opponent, battle history, top trainers.
  class StudioTab
    attr_reader :user, :pokemons, :selected_pokemon, :evolution, :dex_leaderboard,
                :opponent, :battle_history, :attack_team, :defense_team, :defense_away,
                :daily_quests, :weekly_streak, :bag_items, :candies, :lure_types

    # +claim_visit:+ stamps last_studio_visit_at after reading the away report (Studio tab only).
    def initialize(user, claim_visit: false)
      @user = user
      @pokemons = UserPokemonListQuery.new(user).call.load
      @dex_leaderboard = Pokemons::DexLeaderboard.new
      @attack_team = TeamRoster.new(user, :attack, party: @pokemons).records
      @defense_team = TeamRoster.new(user, :defense, party: @pokemons).records
      @defense_away = claim_visit ? DefenseAway.claim!(user) : DefenseAway::NONE
      assign_inventory
      assign_pokemon_details if @pokemons.any?
    end

    def leaderboard_cooldown?
      return @leaderboard_cooldown if defined?(@leaderboard_cooldown)

      @leaderboard_cooldown = BattleLeaderboardCooldown.call(user)
    end

    def reroll_available?
      @reroll_available
    end

    def top_trainers
      @top_trainers ||= DexLeaderboard.top
    end

    private

    def assign_inventory
      @daily_quests = DailyQuests::EnsureToday.call(user)
      @weekly_streak = DailyQuests::WeeklyStreak.status(user)
      @candies = user.trainer_profile.candies
      @bag_items = user.trainer_items.where('quantity > 0').order(:item_key).to_a
      @lure_types = Habitat.known_type_keys.sort
    end

    def assign_pokemon_details
      @selected_pokemon = @pokemons.first
      @evolution = @selected_pokemon.next_evolution
      assign_opponent
      @battle_history = user.latest_battle
    end

    def assign_opponent
      matchmaker = Matchmaker.new(user, leaderboard: dex_leaderboard)
      @opponent = matchmaker.opponent unless leaderboard_cooldown?
      @reroll_available = matchmaker.reroll_available?
    end
  end
end
