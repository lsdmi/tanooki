# frozen_string_literal: true

module Pokemons
  # Read-model for the Studio "Pokémons" tab: party list, dex ranks, opponent, battle history, top trainers.
  class StudioTab
    attr_reader :user, :pokemons, :selected_pokemon, :evolution, :dex_leaderboard,
                :opponent, :battle_history

    def initialize(user)
      @user = user
      @pokemons = UserPokemonListQuery.new(user).call.load
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

    def assign_pokemon_details
      @selected_pokemon = @pokemons.first
      @evolution = @selected_pokemon.next_evolution
      @dex_leaderboard = Pokemons::DexLeaderboard.new
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
