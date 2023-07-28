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
          'filtered-fictions', partial: 'other_section', locals: { other: @other }
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
          'chapters-list', partial: 'chapter_list', locals: { fiction: @fiction, user_id: params[:translator] }
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
      manage_genres if params[:fiction][:genre_ids]
      redirect_to fiction_path(@fiction), notice: 'Твір створено.'
    else
      render 'fictions/new', status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fiction.update(fiction_params)
      manage_genres if params[:fiction][:genre_ids]
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

  def index_variables
    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
    @popular_fictions = popular_fictions
    @most_reads = most_reads
    @latest_updates = latest_updates
    @hot_updates = hot_updates
    setup_filtered_fictions
  end

  def manage_genres
    fiction_genres_ids = params[:fiction][:genre_ids].reject(&:empty?).map(&:to_i)
    existing_genre_ids = @fiction.genres.ids

    genres_to_add = fiction_genres_ids - existing_genre_ids
    genres_to_remove = existing_genre_ids - fiction_genres_ids

    genres_to_add.each { |genre_id| @fiction.fiction_genres.create(genre_id:) }
    genres_to_remove.each { |genre_id| @fiction.fiction_genres.find_by(genre_id:).destroy }
  end

  def most_reads
    Rails.cache.fetch('most_reads', expires_in: 12.hours) do
      Fiction.most_reads.limit(5)
    end
  end

  def popular_fictions
    Rails.cache.fetch('popular_fictions', expires_in: 12.hours) do
      Fiction.includes([{ cover_attachment: :blob }, :genres]).order(views: :desc).limit(5)
    end
  end

  def latest_updates
    fiction_with_max_created_at_query.limit(9)
  end

  def hot_updates
    Rails.cache.fetch('hot_updates', expires_in: 12.hours) do
      fiction_with_recent_hot_updates_query.limit(5)
    end
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

  def fiction_list
    if current_user.admin?
      Fiction.all
    else
      Fiction.joins(:chapters)
             .where(chapters: { user_id: current_user.id })
             .or(Fiction.where(user_id: current_user.id))
             .distinct
    end
  end

  def fiction_params
    params.require(:fiction).permit(
      :alternative_title, :author, :cover, :description, :english_title,
      :genre_ids, :status, :title, :translator, :total_chapters, :user_id
    )
  end

  def next_chapter
    first_chapter = ordered_chapters(@fiction).first

    return first_chapter unless @reading_progress.present?

    following_chapter(
      @reading_progress.chapter.fiction,
      @reading_progress.chapter
    ) || first_chapter
  end

  def ordered_fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def set_fiction
    @fiction = @commentable = Fiction.find(params[:id])
  end

  def split_chapter_list
    fiction_chapters = ordered_chapters_desc(@fiction)
    next_chapter_index = fiction_chapters.index(@next_chapter)

    return unless next_chapter_index

    @before_next_chapter = fiction_chapters[0...next_chapter_index + 1]
    @after_next_chapter = fiction_chapters[next_chapter_index + 1..]
  end

  def split_chapter_by_user_id
    all_chapters = ordered_chapters_desc(@fiction)

    params[:translator] ||= all_chapters.first.user_id

    fiction_chapters = chapters_by_translator(all_chapters)
    next_chapter_index = next_chapter_index(fiction_chapters, @next_chapter)

    return if next_chapter_index.nil?

    @before_next_chapter = before_next_chapter_splitted(next_chapter_index, fiction_chapters)
    @after_next_chapter = after_next_chapter_splitter(next_chapter_index, fiction_chapters)
  end

  def chapters_by_translator(chapters)
    chapters.select { |chapter| chapter.user_id == params[:translator].to_i }
  end

  def before_next_chapter_splitted(index, chapters)
    index == -1 ? [] : chapters[0...index + 1]
  end

  def after_next_chapter_splitter(index, chapters)
    index == -1 ? chapters : chapters[index + 1..]
  end

  def show_vars
    @comments = @fiction.comments.parents.includes(:replies, :user).order(created_at: :desc)
    @comment = Comment.new
    @reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user&.id)
    @next_chapter = next_chapter
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
