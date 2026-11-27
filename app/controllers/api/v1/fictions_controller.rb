# frozen_string_literal: true

module Api
  module V1
    # Public JSON list of fictions for external integrations (e.g. Hikka).
    class FictionsController < ApplicationController
      def index
        render json: ::Fictions::HikkaFeed.fetch
      end
    end
  end
end
