# frozen_string_literal: true

class ReadingProgressesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fiction

  def update_status
    handle_reading_progress_update
    render_status_update
  end

  private

  def handle_reading_progress_update
    reading_progress = find_or_create_reading_progress
    update_existing_progress(reading_progress) if reading_progress
  end

  def find_or_create_reading_progress
    ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user.id) ||
      create_new_reading_progress
  end

  def create_new_reading_progress
    first_chapter = ordered_chapters(@fiction).first
    return unless first_chapter

    ReadingProgress.create!(
      fiction_id: @fiction.id,
      user_id: current_user.id,
      chapter_id: first_chapter.id,
      status: params[:status]&.to_sym || :active
    )
  end

  def update_existing_progress(reading_progress)
    new_status = params[:status]&.to_sym
    ReadingProgressStatusService.new(reading_progress, new_status, current_user).call
  end

  def render_status_update
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, params)
    render turbo_stream: turbo_stream.update(
      'fiction-reading-status',
      partial: 'fictions/reading_status_controls',
      locals: { fiction: @fiction, show_presenter: @show_presenter }
    )
  end

  def set_fiction
    @fiction = Fiction.find(params[:fiction_id])
  end

  def ordered_chapters(fiction)
    fiction.chapters.order(:number)
  end
end
