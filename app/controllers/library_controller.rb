# frozen_string_literal: true

# Personal library: reading history, status updates, and recommendations.
class LibraryController < ApplicationController
  helper Library::ChapterCatalogHelper,
         Library::ChapterNavigationHelper,
         Library::ReadingStateHelper

  before_action :authenticate_user!
  before_action :pokemon_appearance, only: [:index]

  def index
    data = Library::SectionDataBuilder.new(current_user, section_param).call

    @section = data[:section]
    @history = data[:history]
    @history_presenter = data[:history_presenter]
    @pagy, @paginated_readings = pagy_array(data[:section_data], limit: 8)
    @related_fictions = related_fictions
    @favourite_translators = favourite_translators
  end

  def update_status
    reading_progress = current_user.readings.find(params.expect(:id))
    current_section = params[:current_section]&.to_sym || :active
    @status_update_result = Reading::UpdateStatus.new(
      reading_progress, params[:status], current_user
    ).call
    refresh_library_list(current_section)
    render_library_list(current_section)
  end

  private

  def refresh_library_list(section)
    library_data = Library::SectionDataBuilder.new(current_user, section).call
    @pagy, @paginated_readings = pagy_array(library_data[:section_data], limit: 8)
  end

  def related_fictions
    Rails.cache.fetch("user:#{current_user.id}:related_fictions:#{@section}", expires_in: 5.minutes) do
      Library::RelatedFictionsFromReadings.new(
        @history_presenter.section(:active),
        5,
        exclude_ids: @history.to_set(&:fiction_id)
      ).call
    end
  end

  def favourite_translators
    Rails.cache.fetch("user:#{current_user.id}:favourite_translators:#{@section}", expires_in: 5.minutes) do
      Library::TopScanlatorsFromReadings.new(@history_presenter.section(:active)).call
    end
  end

  def section_param
    params.fetch(:section, :active).to_sym
  end

  def render_library_list(section)
    streams = turbo_stream_list_refresh(library_list_stream(section))
    streams.concat(invalid_reading_status_notice) if @status_update_result&.failure?
    render turbo_stream: streams
  end

  def library_list_stream(section)
    turbo_stream.update(
      'library-list',
      partial: 'library/list',
      locals: { paginated_readings: @paginated_readings, pagy: @pagy, section: section }
    )
  end

  def invalid_reading_status_notice
    turbo_stream_notice(t('reading_progress.alerts.invalid_status'))
  end
end
