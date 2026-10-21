# frozen_string_literal: true

module Users
  # Saves the signed-in reader's discovery filter and redraws the settings card.
  class ContentFiltersController < ApplicationController
    before_action :authenticate_user!

    def update
      result = ContentFilters::Replace.call(
        user: current_user,
        max_content_rating: filter_params[:max_content_rating],
        hidden_genre_ids: filter_params[:hidden_genre_ids]
      )
      streams = result.success? ? turbo_stream_notice(t('content_filters.saved')) : turbo_stream_alert(result.error)
      status = result.success? ? :ok : :unprocessable_content
      render turbo_stream: [*streams, replace_card(result.error)], status:
    end

    private

    def filter_params
      params.permit(:max_content_rating, hidden_genre_ids: [])
    end

    def replace_card(error)
      turbo_stream.replace('content-filter-card', partial: 'studio/tabs/content_filter', locals: { error: })
    end
  end
end
