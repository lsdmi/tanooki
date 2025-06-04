# frozen_string_literal: true

class PokemonShow
  attr_reader :user, :pokemons, :selected_pokemon, :descendant, :dex_overall,
              :opponent, :battle_history

  def initialize(user)
    @user = user
    @pokemons = pokemons_cache
    assign_pokemon_details if @pokemons.any?
  end

  private

  def assign_pokemon_details
    @selected_pokemon = @pokemons.first
    @descendant = @selected_pokemon.pokemon.descendant
    @dex_overall = dex_leaders
    @opponent = find_opponent
    @battle_history = fetch_battle_history
  end

  def find_opponent
    Rails.cache.fetch("opponent_for_user:#{user.id}", expires_in: 5.minutes) do
      index = dex_overall.index(user)
      size = dex_overall.size
      DexLeaderboard.new(index, size).call.then { |idx| dex_overall[idx] }
    end
  end

  def fetch_battle_history
    Rails.cache.fetch("user:#{user.id}:battle_history", expires_in: 5.minutes) do
      user.battle_logs_includes_details.sort_by { |log| -log.id }.first(10)
    end
  end

  def pokemons_cache
    Rails.cache.fetch("user:#{user.id}:pokemons", expires_in: 5.minutes) do
      UserPokemonListQuery.new(user).call
    end
  end

  def dex_leaders
    Rails.cache.fetch('dex_leaders', expires_in: 5.minutes) do
      User.dex_leaders
    end
  end
end
