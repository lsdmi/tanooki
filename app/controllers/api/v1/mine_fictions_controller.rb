# frozen_string_literal: true

module Api
  module V1
    # Fictions the token's teams work on.
    class MineFictionsController < BaseController
      before_action { enforce_scope('chapters:read') }

      def index
        fictions = Api::Fictions::MineQuery.call(Current.user, query: params[:q])
        render json: { fictions: }
      end
    end
  end
end
