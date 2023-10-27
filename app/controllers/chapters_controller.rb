# frozen_string_literal: true

class ChaptersController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[show]
  before_action :set_chapter, only: %i[show edit update destroy]
  before_action :track_visit, :load_advertisement, :track_reading_progress, only: :show
  before_action :verify_permissions, except: %i[new create show]

  def show
    @comments = @chapter.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @next_chapter = following_chapter(@chapter.fiction, @chapter)
    @more_from_author = more_from_author
  end

  def new
    @chapter = Chapter.new
  end

  def create
    @chapter = Chapter.new(chapter_params)

    if @chapter.save
      ChapterScanlatorsManager.new(chapter_params[:scanlator_ids], @chapter).operate
      update_fiction_status
      redirect_to readings_path, notice: 'Розділ додано.'
    else
      render 'chapters/new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @chapter.update(chapter_params)
      ChapterScanlatorsManager.new(chapter_params[:scanlator_ids], @chapter).operate
      redirect_to readings_path, notice: 'Розділ оновлено.'
    else
      render 'chapters/edit', status: :unprocessable_entity
    end
  end

  def destroy
    @chapter.destroy
    chapter_page = params["chapter_page_#{@chapter.fiction_slug}"]
    chapter_page = (chapter_page.to_i - 1) if chapters.size <= (chapter_page.to_i * 8) - 8
    setup_pagination(chapters, chapter_page)
    render turbo_stream: refresh_list
  end

  private

  def announced_dropped_new_status(actual_size, total_size)
    actual_size >= total_size ? Fiction.statuses[:finished] : Fiction.statuses[:ongoing]
  end

  def ongoing_new_status(actual_size, total_size, current_status)
    actual_size >= total_size ? Fiction.statuses[:finished] : current_status
  end

  def new_fiction_status(current_status, total_chapters, actual_chapters)
    case Fiction.statuses[current_status]
    when Fiction.statuses[:announced], Fiction.statuses[:dropped]
      announced_dropped_new_status(actual_chapters.size, total_chapters)
    when Fiction.statuses[:ongoing]
      ongoing_new_status(actual_chapters.size, total_chapters, current_status)
    else
      current_status
    end
  end

  def more_from_author
    Rails.cache.fetch("more_from_author_#{@chapter.id}}", expires_in: 12.hours) do
      fictions_from_author
    end
  end

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def chapters
    ordered_chapters_desc(@chapter.fiction)
  end

  def setup_pagination(chapters, page)
    return if page && page.to_i < 1

    @pagination = pagy(
      chapters, page:, items: 8, request_path: readings_path, page_param: "chapter_page_#{@chapter.fiction_slug}"
    )
  end

  def chapter_params
    params.require(:chapter).permit(
      :content, :fiction_id, :number, :title, :user_id, :volume_number, scanlator_ids: []
    )
  end

  def refresh_list
    turbo_stream.update(
      "chapter-list-#{@chapter.fiction_slug}",
      partial: 'users/dashboard/chapter_list',
      locals: { fiction: @chapter.fiction, pagination: @pagination }
    )
  end

  def track_reading_progress
    ReadingProgressTracker.new(chapter: @chapter, user: current_user).call
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.chapters.include?(@chapter)
  end

  def update_fiction_status
    new_status = new_fiction_status(
      @chapter.fiction.status,
      @chapter.fiction.total_chapters,
      unique_chapters(@chapter.fiction.chapters)
    )
    @chapter.fiction.update(status: new_status)
  end
end
