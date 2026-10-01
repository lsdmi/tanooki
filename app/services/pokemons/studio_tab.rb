# frozen_string_literal: true

module Pokemons
  # Read-model for the Studio "Pokémons" tab: party list, dex ranks, opponent, battle history.
  class StudioTab
    attr_reader :user, :pokemons, :selected_pokemon, :descendant, :dex_leaderboard,
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

    private

    def assign_pokemon_details
      @selected_pokemon = @pokemons.first
      @descendant = Pokemon.find_by(id: @selected_pokemon.pokemon.descendant_id)
      @dex_leaderboard = Pokemons::DexLeaderboard.new
      assign_opponent
      @battle_history = fetch_battle_history
    end

    def assign_opponent
      matchmaker = Matchmaker.new(user, leaderboard: dex_leaderboard)
      @opponent = matchmaker.opponent unless leaderboard_cooldown?
      @reroll_available = matchmaker.reroll_available?
    end

    def fetch_battle_history
      Rails.cache.fetch("user:#{user.id}:battle_history", expires_in: 5.minutes) do
        user.latest_battle_log
      end
    end
  end
end
