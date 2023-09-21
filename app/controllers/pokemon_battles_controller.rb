# frozen_string_literal: true

class PokemonBattlesController < ApplicationController
  def start
    if possible_fraud?
      redirect_to pokemons_path, alert: PokemonBattleLog::POTENTIAL_FRAUD_ALERT
    else
      battle_service.start_battle

      PokemonBattleLog.create(
        attacker_id: current_user.id,
        defender_id: params[:defender],
        winner_id: battle_service.winner_id,
        details: battle_service.fight_details
      )

      experience_distributor = PokemonExperienceDistributor.new(winner_id: battle_service.winner_id,
                                                                loser_id: battle_service.loser_id)
      experience_distributor.refresh

      render turbo_stream: refresh_screen
    end
  end

  private

  def battle_service
    @battle_service ||= PokemonBattleService.new(
      attacker_pokemons: current_user.user_pokemons,
      defender_pokemons: defender.user_pokemons,
      attacker_id: current_user.id,
      defender_id: params[:defender]
    )
  end

  def defender
    User.find(params[:defender])
  end

  def possible_fraud?
    (current_user.id == defender.id) ||
      (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago ||
      (defender.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago
  end

  def refresh_screen
    turbo_stream.update(
      'pokemons-screen',
      partial: 'users/dashboard/pokemons',
      locals: { pokemons:, dex_leaderboard:, all_pokemon_count:, all_caught_count:, selected_pokemon:, descendant:,
                battle_history: }
    )
  end

  def pokemons
    UserPokemon.includes(pokemon: { sprite_attachment: :blob }).where(user_id: current_user).order('pokemons.dex_id')
  end

  def dex_leaderboard
    User.dex_leaders
  end

  def all_pokemon_count
    Pokemon.count
  end

  def all_caught_count
    UserPokemon.count
  end

  def selected_pokemon
    pokemons.first
  end

  def descendant
    selected_pokemon.pokemon.descendant
  end

  def battle_history
    current_user.battle_logs_includes_details.sort_by { |log| -log.id }
  end
end
