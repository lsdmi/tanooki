# frozen_string_literal: true

module Oauth
  # Consent screen. Publish is granted only when the member checks it. No team means no grant.
  class AuthorizationsController < Doorkeeper::AuthorizationsController
    layout 'application'

    before_action :normalize_scope, only: :create
    before_action :require_team, only: %i[new create]

    def new
      super
    end

    def create
      super
    end

    private

    def normalize_scope
      params[:scope] = posted_scopes.join(' ')
    end

    def require_team
      return if current_user.scanlators.exists?
      return unless pre_auth.authorizable?

      render :needs_team, status: :forbidden
    end

    def posted_scopes
      Array(params[:scope]).flat_map { |value| value.to_s.split } & RegisterClient::GRANTABLE
    end
  end
end
