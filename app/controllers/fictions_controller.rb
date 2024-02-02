# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[index show toggle_order]
  before_action :set_fiction, only: %i[show edit update destroy toggle_order]
  before_action :set_genres, only: %i[new create edit update]
  before_action :load_advertisement, :track_visit, only: :show
  before_action :verify_permissions, except: %i[index new create show toggle_order]
  before_action :verify_create_permissions, only: %i[new create]

  def index
    index_variables

    respond_to do |format|
      format.html { render 'index' }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'filtered-fictions', partial: 'other_section', locals: { other: @other, genres: @genres,
                                                                   sample_genre: @sample_genre }
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
          'sort-chapters', partial: 'chapters', locals: {
            fiction: @fiction,
            translator: params[:translator].join('-'),
            reading_progress: @reading_progress,
            before_next_chapter: @before_next_chapter,
            order: @order
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
    if @fiction.scanlators.size > 1
      current_user.scanlators.each { |scanlator| destroy_association(scanlator) }
    else
      @fiction.destroy
    end

    @pagy, @fictions = pagy(
      ordered_fiction_list,
      items: 8,
      request_path: readings_path,
      page: fiction_page || 1
    )
    setup_paginator
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  def toggle_order
    show_vars

    render turbo_stream: [
      turbo_stream.update(
        'sort-chapters',
        partial: 'chapters', locals: {
          before_next_chapter: @before_next_chapter,
          fiction: @fiction,
          reading_progress: @reading_progress,
          order: params[:order].to_sym == :desc ? :asc : :desc,
          translator: params[:translator]
        }
      )
    ]
  end

  private

  def destroy_association(scanlator)
    chapters = @fiction.chapters.joins(:scanlators).where(chapter_scanlators: { scanlator_id: scanlator.id })
    chapters.destroy_all

    fiction_scanlator = FictionScanlator.find_by(fiction_id: @fiction.id, scanlator_id: scanlator.id)
    fiction_scanlator&.destroy
  end

  def chapter_manager
    FictionChapterListManager.new(@fiction, @reading_progress, params[:translator])
  end

  def index_variables
    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
    @popular_novelty = FictionIndexVariablesManager.popular_novelty
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
      :title, :total_chapters, genre_ids: [], scanlator_ids: []
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
  end

  def split_chapter_by_user_id
    params[:translator] ||= chapter_manager.translator
    params[:translator] = Array(params[:translator]) unless params[:translator].is_a?(Array)

    if params[:translator].any? { |translator| !@fiction.scanlators.ids.include?(translator.to_i) }
      params[:translator] = chapter_manager.translator
    end

    @before_next_chapter = chapter_manager.before_next_chapter_by_user
  end

  def show_vars
    @comments = @fiction.comments.parents.includes(:replies, :user).order(created_at: :desc)
    @comment = Comment.new
    @reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user&.id)
    @bookmark_stats = bookmark_stats
    @ranks = fiction_ranks
    @order = params[:order] || :desc
    duplicate_chapters(@fiction).any? ? split_chapter_by_user_id : split_chapter_list
  end

  def bookmark_stats
    Rails.cache.fetch("fiction-#{@fiction.slug}-stats", expires_in: 4.hours) do
      BookmarksAccounter.new(fiction: @fiction).call
    end
  end

  def fiction_ranks
    Rails.cache.fetch("fiction-#{@fiction.slug}-ranks", expires_in: 24.hours) do
      FictionRanker.new(fiction: @fiction).call.sort_by { |_genre, rank| rank }.to_h
    end
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

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.fictions.include?(@fiction)
  end

  def verify_create_permissions
    redirect_to new_scanlator_path unless current_user.admin? || current_user.scanlators.any?
  end
end
