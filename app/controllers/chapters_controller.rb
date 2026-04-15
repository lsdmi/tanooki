# frozen_string_literal: true

class ChaptersController < ApplicationController
  include ChapterScheduleParams
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[show comments]
  before_action :set_chapter, only: %i[show edit update comments]
  before_action :redirect_if_chapter_not_yet_public, only: %i[show comments]
  before_action :track_visit, :track_reading_progress, only: :show
  before_action :verify_permissions, except: %i[new create show comments]
  before_action :pokemon_appearance, only: [:show]

  def show
    @comments = load_chapter_comments
    @comment = Comment.new
    @previous_chapter = previous_chapter(@chapter.fiction, @chapter, viewer: current_user)
    @next_chapter = following_chapter(@chapter.fiction, @chapter, viewer: current_user)
  end

  def comments
    @comments = load_chapter_comments
    @comment = Comment.new
    @commentable = @chapter
  end

  def new
    @chapter = Chapter.new
  end

  def create
    @chapter = Chapter.new(chapter_params)
    return render_new_with_schedule_error if published_at_schedule_invalid?

    persist_new_chapter
  end

  def edit; end

  def update
    return render_edit_with_schedule_error if published_at_schedule_invalid?

    persist_chapter_update
  end

  private

  def persist_new_chapter
    if @chapter.save
      ChapterScanlatorsManager.new(chapter_params[:scanlator_ids], @chapter).operate
      update_fiction_status
      redirect_to reading_path(@chapter.fiction), notice: 'Розділ додано.'
    else
      render 'chapters/new', status: :unprocessable_content
    end
  end

  def persist_chapter_update
    if @chapter.update(chapter_params)
      ChapterScanlatorsManager.new(chapter_params[:scanlator_ids], @chapter).operate
      redirect_to reading_path(@chapter.fiction), notice: 'Розділ оновлено.'
    else
      render 'chapters/edit', status: :unprocessable_content
    end
  end

  def load_chapter_comments
    @chapter.comments.parents.includes(
      user: { avatar: :image_attachment },
      replies: { user: { avatar: :image_attachment } }
    ).order(created_at: :desc)
  end

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def chapter_params
    permitted = params.require(:chapter).permit(
      :content, :fiction_id, :number, :title, :user_id, :volume_number,
      :published_at_date, :published_at_time,
      scanlator_ids: []
    )
    merge_published_at_from_schedule_fields(permitted)
  end

  def track_reading_progress
    ReadingProgressTracker.new(chapter: @chapter, user: current_user).call
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.chapters.include?(@chapter)
  end

  def redirect_if_chapter_not_yet_public
    return unless @chapter.scheduled?
    return if current_user&.admin?
    return if current_user && current_user.scanlators.ids.intersect?(@chapter.scanlators.ids)

    redirect_to fiction_path(@chapter.fiction), alert: 'Цей розділ ще недоступний для читання.'
  end

  def update_fiction_status
    new_status = FictionStatusTracker.new(@chapter.fiction).call
    @chapter.fiction.status = new_status
    @chapter.fiction.save(validate: false)
  end
end
