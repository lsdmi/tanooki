# frozen_string_literal: true

class ChaptersController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[show]
  before_action :set_chapter, only: %i[show edit update destroy]
  before_action :track_visit, :track_reading_progress, only: :show
  before_action :verify_permissions, except: %i[new create show]

  def show
    @comments = @chapter.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @previous_chapter = previous_chapter(@chapter.fiction, @chapter)
    @next_chapter = following_chapter(@chapter.fiction, @chapter)
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

  private

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def chapter_params
    params.require(:chapter).permit(
      :content, :fiction_id, :number, :title, :user_id, :volume_number, scanlator_ids: []
    )
  end

  def track_reading_progress
    ReadingProgressTracker.new(chapter: @chapter, user: current_user).call
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.chapters.include?(@chapter)
  end

  def update_fiction_status
    new_status = FictionStatusTracker.new(@chapter.fiction).call
    @chapter.fiction.status = new_status
    @chapter.fiction.save(validate: false)
  end
end
