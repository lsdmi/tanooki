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

  def destroy
    stack_size = @chapter.fiction.chapters.by_user_scanlators(current_user).size

    @chapter.destroy

    handle_scanlators_destruction(stack_size)

    @pagy, @fictions = pagy(ordered_fiction_list, items: 8, request_path: readings_path, page: fiction_page || 1)

    setup_paginator_and_sidebar
    render turbo_stream: [refresh_list, refresh_sidebar]
  end

  private

  def handle_scanlators_destruction(stack_size)
    return unless @chapter.fiction.scanlators.size > 1 && stack_size == 1

    current_user.scanlators.each { |scanlator| destroy_association(scanlator) }
  end

  def setup_paginator_and_sidebar
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params, current_user)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
    @fictions_size = @pagy.count
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def fiction_page
    (params[:page].to_i - 1) if Fiction.count <= (params[:page].to_i * 8) - 8
  end

  def ordered_fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def destroy_association(scanlator)
    FictionScanlator.find_by(fiction_id: @chapter.fiction.id, scanlator_id: scanlator.id)&.destroy
  end

  def set_chapter
    @chapter = @commentable = Chapter.find(params[:id])
  end

  def chapters
    ordered_chapters_desc(@chapter.fiction)
  end

  def chapter_params
    params.require(:chapter).permit(
      :content, :fiction_id, :number, :title, :user_id, :volume_number, scanlator_ids: []
    )
  end

  def refresh_list
    turbo_stream.update(
      'fictions-list',
      partial: 'users/dashboard/fictions',
      locals: { fictions: @fictions, pagy: @pagy, paginators: @paginators }
    )
  end

  def refresh_sidebar
    turbo_stream.update(
      'default-sidebar',
      partial: 'users/dashboard/sidebar',
      locals: { user_publications: @user_publications, fictions_size: @fictions_size }
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
