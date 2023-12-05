# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      @user = User.from_omniauth(request.env['omniauth.auth'])
      @user.persisted? ? success_google_oauth : failure_google_oauth
    end

    # More info at:
    # https://github.com/heartcombo/devise#omniauth

    # GET|POST /resource/auth/twitter
    # def passthru
    #   super
    # end

    # GET|POST /users/auth/twitter/callback
    # def failure
    #   super
    # end

    protected

    # The path used when OmniAuth fails
    # def after_omniauth_failure_path_for(scope)
    #   super(scope)
    # end

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
      sign_in_and_redirect @user, event: :authentication
    end

    def failure_google_oauth
      session['devise.google_data'] = request.env['omniauth.auth'].except('extra')
      redirect_to register_url, alert: @user.errors.full_messages.join("\n")
    end

    private

    def no_caught_pokemon?
      session[:pokemon_guest_caught].nil? || session[:caught_pokemon_id].nil?
    end
  end
end
