# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :configure_sign_up_params, only: [:create]

    # GET /resource/sign_up
    def new
      handle_pokemon_notice
      super
    end

    # POST /resource
    def create
      super do |user|
        if user.persisted?
          inactive_kind = PokemonSignupHandler.new(user, session).perform
          set_flash_message! :notice, :"signed_up_but_#{inactive_kind}" if inactive_kind
        else
          set_flash_message! :alert, :sign_up_error
        end
      end
    end

    protected

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[name avatar_id])
    end

    def after_sign_up_path_for(_resource)
      root_path
    end

    private

    def handle_pokemon_notice
      return unless params[:pokenotice].present? && session[:caught_pokemon_id].present?

      session[:pokemon_guest_caught] = true
      set_flash_message! :notice, :pokemon_login_error
    end
  end
end
