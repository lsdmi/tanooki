# frozen_string_literal: true

module Api
  module V1
    # Public description of the team API. No token: tools need to read it before they can call.
    class OpenapiController < ActionController::API
      def show
        render json: Api::Openapi::DOCUMENT
      end
    end
  end
end
