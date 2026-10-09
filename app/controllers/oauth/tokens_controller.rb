# frozen_string_literal: true

module Oauth
  # Token endpoint. An unused refresh token dies after 90 days.
  class TokensController < Doorkeeper::TokensController
    before_action :reject_stale_refresh, only: :create

    def create
      super
    end

    private

    def reject_stale_refresh
      return unless params[:grant_type] == 'refresh_token'

      token = Doorkeeper::AccessToken.by_refresh_token(params[:refresh_token].to_s)
      return if token.nil? || token.created_at.after?(RegisterClient::REFRESH_TTL.ago)

      token.revoke
      render json: { error: 'invalid_grant' }, status: :bad_request
    end
  end
end
