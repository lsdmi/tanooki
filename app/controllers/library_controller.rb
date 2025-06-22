# frozen_string_literal: true

class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    @history = fetch_reading_history
    @history_presenter = ReadingHistoryPresenter.new(@history)
    @section = section_param
    @readings_section = @history_presenter.section(@section)

    @pagy, @paginated_readings = pagy_array(@readings_section, limit: 8)
    @related_fictions = RelatedFictionsCollector.new(@history_presenter.section(:active), 5).collect
    @favourite_translators = FavouriteTranslatorsFinder.new(@history_presenter.section(:active)).find

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

  def fetch_reading_history
    current_user.readings.includes(
      [{ fiction: :cover_attachment }, :chapter]
    ).order(updated_at: :desc)
  end

  def section_param
    params[:section]&.to_sym || :active
  end
end
