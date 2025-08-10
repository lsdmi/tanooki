# frozen_string_literal: true

class OmniauthCallbacksController < ApplicationController
  def google_oauth2
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted? && @user.valid?
      success_google_oauth
    else
      failure_google_oauth
    end
  end

  protected

  def notice_pokemon_catch
    if no_caught_pokemon?
      no_pokemon_notice
    else
      pokemon_notice
    end
  end

  def no_pokemon_notice
    PokemonCatchService.new(pokemon_id: nil, user_id: @user.id).grant if @user&.pokemons&.empty?
    flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
  end

  def pokemon_notice
    PokemonCatchService.new(pokemon_id: session[:caught_pokemon_id], user_id: @user.id).trap
    flash[:notice] = I18n.t 'devise.omniauth_callbacks.success_with_pokemon', kind: 'Google'
  end

  def success_google_oauth
    notice_pokemon_catch
    start_new_session_for(@user)
    redirect_to after_authentication_url
  end

  def failure_google_oauth
    redirect_to new_session_path, alert: @user.errors.full_messages.join("\n")
  end

  private

  def no_caught_pokemon?
    session[:pokemon_guest_caught].nil? || session[:caught_pokemon_id].nil?
  end
end
