# frozen_string_literal: true

module Api
  module V1
    # Public JSON list of fictions for external integrations (e.g. Hikka).
    class FictionsController < ApplicationController
      def index
        @fictions = Rails.cache.fetch('fictions_hikka', expires_in: 1.hour) do
          Fiction.with_attached_cover.map(&:as_hikka_json)
        end
        render json: @fictions
      end
    end
  end
end
