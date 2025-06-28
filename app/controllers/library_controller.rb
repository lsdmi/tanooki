# frozen_string_literal: true

class LibraryController < ApplicationController
  before_action :authenticate_user!

  def index
    data = LibraryDataService.new(current_user, section_param, page_param).call

    @section = data[:section]
    @history = data[:history]
    @history_presenter = data[:history_presenter]
    @pagy, @paginated_readings = pagy_array(data[:section_data], limit: 8)
    @related_fictions = related_fictions
    @favourite_translators = favourite_translators
  end

  def update_status
    reading_progress = ReadingProgress.find(params[:id])
    new_status = params[:status]&.to_sym
    current_section = params[:current_section]&.to_sym || :active

    ReadingProgressStatusService.new(reading_progress, new_status, current_user).call
    library_data = LibraryDataService.new(current_user, current_section, page_param).call

    @pagy, @paginated_readings = pagy_array(library_data[:section_data], limit: 8)

    render_library_list(current_section)
  end

  private

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

  def page_param
    params[:page]&.to_i || 1
  end

  def render_library_list(section)
    render turbo_stream: turbo_stream.update(
      'library-list',
      partial: 'library/list',
      locals: {
        paginated_readings: @paginated_readings,
        pagy: @pagy,
        section: section
      }
    )
  end
end
