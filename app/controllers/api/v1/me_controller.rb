# frozen_string_literal: true

module Api
  module V1
    # Who the token is. Any valid token may call it.
    class MeController < BaseController
      def show
        render json: {
          user: { id: Current.user.id, name: Current.user.name },
          teams: team_list,
          token: token_payload,
          limits: Limits::Usage.snapshot(Current.user)
        }
      end

      private

      def team_list
        Current.user.scanlators.order(:title).map { |team| { id: team.id, name: team.title } }
      end

      def token_payload
        token = Current.api_token
        { prefix: token.token_prefix, scopes: token.scopes, expires_at: token.expires_at.iso8601 }
      end
    end
  end
end
