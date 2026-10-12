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
    paginate_readings(data[:section_data])
    @related_fictions = related_fictions
    @favourite_translators = favourite_translators
  end

  # A move or a removal drops the row from the tab with a toast, so the reader stays on their page. The whole list is
  # redrawn when the tab empties (for its empty state) or nothing moved.
  def update_status
    reading_progress = current_user.readings.find(params.expect(:id))
    section = current_section_param
    @status_update_result = update_reading_status(reading_progress)
    readings = section_readings(section)
    notice = moved_notice(reading_progress, section)
    return render_row_removal(reading_progress, notice) if notice && readings.any?

    paginate_readings(readings)
    render_library_list(section, notice)
  end

  private

  def paginate_readings(readings)
    @pagy, @paginated_readings = pagy_array(readings, limit: 8)
    Library::EntryPreload.call(@paginated_readings, viewer: current_user)
  end

  def update_reading_status(reading_progress)
    Reading::UpdateStatus.new(reading_progress, params[:status], current_user).call
  end

  def section_readings(section)
    Library::SectionDataBuilder.new(current_user, section).call[:section_data]
  end

  def current_section_param
    section = params[:current_section].to_s
    ReadingProgress.statuses.key?(section) ? section.to_sym : :active
  end

  def moved_notice(reading_progress, section)
    return unless @status_update_result.success?
    return t('library.shelf_menu.removed') if reading_progress.destroyed?

    status = reading_progress.status.to_sym
    t('library.shelf_menu.moved', shelf: Library::ReadingState.status_label_for(status)) unless status == section
  end

  def render_row_removal(reading_progress, notice)
    render turbo_stream: [turbo_stream.remove("reading-progress-#{reading_progress.id}"), *turbo_stream_notice(notice)]
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

  def render_library_list(section, notice)
    streams = turbo_stream_list_refresh(library_list_stream(section))
    streams.concat(turbo_stream_notice(notice)) if notice
    streams.concat(invalid_reading_status_notice) if @status_update_result.failure?
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
