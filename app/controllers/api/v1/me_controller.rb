# frozen_string_literal: true

module Api
  module V1
    # Who the token is. Any valid token may call it.
    class MeController < BaseController
      def show
        token = Current.api_token
        render json: {
          user: { id: Current.user.id, name: Current.user.name },
          teams: Current.user.scanlators.order(:title).map { |team| { id: team.id, name: team.title } },
          token: { prefix: token.token_prefix, scopes: token.scopes, expires_at: token.expires_at.iso8601 }
        }
      end
    end
  end
end
