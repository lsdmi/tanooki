# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    def create
      super
      catch_pokemon(resource)
    end

    # DELETE /resource/sign_out
    # def destroy
    #   super
    # end

    protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end

    def catch_pokemon(resource)
      return if session[:pokemon_guest_caught].nil? || session[:caught_pokemon_id].nil?

      PokemonCatchService.new(pokemon_id: session[:caught_pokemon_id], user_id: resource.id).trap
      set_flash_message! :notice, :signed_in_with_pokemon
    end
  end
end
