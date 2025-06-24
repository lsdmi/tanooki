# frozen_string_literal: true

class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    @section = section_param

    @history = reading_history
    @history_presenter = ReadingHistoryPresenter.new(@history)

    @pagy, @paginated_readings = pagy_array(
      @history_presenter.section(@section),
      limit: 8
    )

    @related_fictions = related_fictions
    @favourite_translators = favourite_translators

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'library-list',
          partial: 'library/list',
          locals: {
            paginated_readings: @paginated_readings,
            pagy: @pagy
          }
        )
      end
    end
  end

  private

  def reading_history
    Rails.cache.fetch("user:#{current_user.id}:reading_history", expires_in: 5.minutes) do
      ReadingHistoryFetcher.new(current_user).call
    end
  end

  def related_fictions
    Rails.cache.fetch("user:#{current_user.id}:related_fictions:#{@section}", expires_in: 5.minutes) do
      RelatedFictionsCollector.new(
        @history_presenter.section(:active),
        5,
        exclude_ids: @history.to_set(&:fiction_id)
      ).collect
    end
  end

  def favourite_translators
    Rails.cache.fetch("user:#{current_user.id}:favourite_translators:#{@section}", expires_in: 5.minutes) do
      FavouriteTranslatorsFinder.new(@history_presenter.section(:active)).find
    end
  end

  def section_param
    params.fetch(:section, :active).to_sym
  end
end
