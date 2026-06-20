# frozen_string_literal: true

# API for updating and clearing per-fiction reading progress.
class ReadingProgressesController < ApplicationController
  helper Library::ReadingStateHelper

  before_action :authenticate_user!
  before_action :set_fiction

  def update_status
    handle_reading_progress_update
    render_status_update
  end

  private

  def handle_reading_progress_update
    @status_update_result = perform_reading_progress_update
  end

  def perform_reading_progress_update
    reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user.id)
    return update_existing_progress(reading_progress) if reading_progress

    create_new_reading_progress
  end

  def create_new_reading_progress
    status = normalized_create_status
    return invalid_status_outcome unless status

    first_chapter = Library::ChapterCatalog.ordered_chapters(@fiction, viewer: current_user).first
    return invalid_status_outcome unless first_chapter

    Outcomes::OperationOutcome.new(
      success: true,
      data: { reading_progress: build_reading_progress(first_chapter, status) }
    )
  end

  def build_reading_progress(first_chapter, status)
    ReadingProgress.create!(
      fiction_id: @fiction.id,
      user_id: current_user.id,
      chapter_id: first_chapter.id,
      status: status
    )
  end

  def normalized_create_status
    status = Reading::UpdateStatus.normalize_status(params[:status], default: 'active')
    return if !status || status == Reading::UpdateStatus::DESTROY_STATUS

    status
  end

  def update_existing_progress(reading_progress)
    Reading::UpdateStatus.new(reading_progress, params[:status], current_user).call
  end

  def invalid_status_outcome
    Outcomes::OperationOutcome.new(success: false)
  end

  def render_status_update
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, params)
    streams = turbo_stream_list_refresh(
      turbo_stream.update(
        'fiction-reading-status',
        partial: 'fictions/reading_status_controls',
        locals: { fiction: @fiction, show_presenter: @show_presenter }
      )
    )
    streams.concat(invalid_reading_status_notice) if @status_update_result&.failure?

    render turbo_stream: streams
  end

  def invalid_reading_status_notice
    turbo_stream_notice(t('reading_progress.alerts.invalid_status'))
  end

  def set_fiction
    @fiction = Fiction.find(params[:fiction_id])
  end
end
