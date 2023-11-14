# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_fiction, only: %i[show edit update destroy]
  before_action :set_genres, only: %i[new create edit update]
  before_action :track_visit, only: :show
  before_action :load_advertisement, only: %i[index show]
  before_action :verify_permissions, except: %i[index new create show]

  def index
    index_variables

    respond_to do |format|
      format.html { render 'index' }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'filtered-fictions', partial: 'other_section', locals: { other: @other, genres: @genres, sample_genre: @sample_genre }
        )
      end
    end
  end

  def show
    show_vars

    respond_to do |format|
      format.html { render 'show' }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          'chapters-list', partial: 'chapter_list', locals: {
            fiction: @fiction, user_id: params[:translator], reading_progress: @reading_progress, before_next_chapter: @before_next_chapter, after_next_chapter: @after_next_chapter
          }
        )
      end
    end
  end

  def new
    @fiction = Fiction.new
  end

  def create
    @fiction = Fiction.new(fiction_params)

    if @fiction.save
      UserFiction.create(fiction_id: @fiction.id, user_id: fiction_params[:user_id]) if fiction_params[:user_id]
      FictionGenresManager.new(fiction_params[:genre_ids], @fiction).operate
      FictionScanlatorsManager.new(fiction_params[:scanlator_ids], @fiction).operate
      redirect_to fiction_path(@fiction), notice: 'Твір створено.'
    else
      render 'fictions/new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fiction.update(fiction_params)
      FictionGenresManager.new(fiction_params[:genre_ids], @fiction).operate
      FictionScanlatorsManager.new(fiction_params[:scanlator_ids], @fiction).operate
      redirect_to fiction_path(@fiction), notice: 'Твір оновлено.'
    else
      render 'fictions/edit', status: :unprocessable_entity
    end
  end

  def destroy
    @fiction.destroy
    @pagy, @fictions = pagy(
      ordered_fiction_list,
      items: 8,
      request_path: readings_path,
      page: fiction_page || 1
    )
    setup_paginator
    setup_sidebar_vars
    render turbo_stream: [refresh_list, refresh_sidebar]
  end

  private

  def chapter_manager
    FictionChapterListManager.new(@fiction, @reading_progress, params[:translator])
  end

  def index_variables
    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
    @popular_fictions = FictionIndexVariablesManager.popular_fictions
    @most_reads = FictionIndexVariablesManager.most_reads
    @latest_updates = FictionIndexVariablesManager.latest_updates
    @hot_updates = FictionIndexVariablesManager.hot_updates
    setup_filtered_fictions
  end

  def set_genres
    @genres = Genre.all.order(:name)
  end

  def setup_paginator
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params, current_user)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
  end

  def fiction_page
    (params[:page].to_i - 1) if Fiction.count <= (params[:page].to_i * 8) - 8
  end

  def fiction_params
    params.require(:fiction).permit(
      :alternative_title, :author, :cover, :description, :english_title, :status,
      :title, :total_chapters, :user_id, genre_ids: [], scanlator_ids: []
    )
  end

  def ordered_fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def set_fiction
    @fiction = @commentable = Fiction.find(params[:id])
  end

  def split_chapter_list
    @before_next_chapter = chapter_manager.before_next_chapter
    @after_next_chapter = chapter_manager.after_next_chapter
  end

  def split_chapter_by_user_id
    params[:translator] ||= chapter_manager.translator
    @before_next_chapter = chapter_manager.before_next_chapter_by_user
    @after_next_chapter = chapter_manager.after_next_chapter_by_user
  end

  def show_vars
    @comments = @fiction.comments.parents.includes(:replies, :user).order(created_at: :desc)
    @comment = Comment.new
    @reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user&.id)
    @next_chapter = chapter_manager.next_chapter
    duplicate_chapters(@fiction).any? ? split_chapter_by_user_id : split_chapter_list
  end

  def refresh_list
    turbo_stream.update(
      'fictions-list',
      partial: 'users/dashboard/fictions',
      locals: { fictions: @fictions, pagy: @pagy, paginators: @paginators }
    )
  end

  def setup_filtered_fictions
    @genres = Genre.joins(:fictions).order(:name).distinct
    params[:genre_id] ||= @genres.sample.id

    @sample_genre = @genres.find_by(id: params[:genre_id]) || @genres.sample
    params[:genre_id] = @sample_genre.id

    @other = filtered_fiction_with_max_created_at_query
  end

  def setup_sidebar_vars
    @fictions_size = @pagy.count
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def refresh_sidebar
    turbo_stream.update(
      'default-sidebar',
      partial: 'users/dashboard/sidebar',
      locals: { user_publications: @user_publications, fictions_size: @fictions_size }
    )
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.fictions.include?(@fiction)
  end
end
