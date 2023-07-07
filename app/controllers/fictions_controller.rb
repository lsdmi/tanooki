# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_fiction, only: %i[show edit update destroy]
  before_action :set_genres, only: %i[new create edit update]
  before_action :track_visit, only: :show
  before_action :load_advertisement, only: %i[index show]
  before_action :verify_permissions, except: %i[index new create show]

  def index
    @hero_ad = Advertisement.find_by(slug: 'fictions-index-hero-ad')
    @popular_fictions = popular_fictions
    @most_reads = most_reads
    @latest_updates = latest_updates
    @hot_updates = hot_updates
    @other = other
    @other_mobile = other_mobile
  end

  def show
    @comments = @fiction.comments.parents.includes(:replies, :user).order(created_at: :desc)
    @comment = Comment.new

    reading_progress_vars
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
      Fiction.all.order(:title),
      items: 8,
      request_path: readings_path,
      page: fiction_page || 1
    )
    setup_paginator
    setup_sidebar_vars
    render turbo_stream: [refresh_list, refresh_sidebar]
  end

  private

  def manage_genres
    fiction_genres_ids = params[:fiction][:genre_ids].map(&:to_i)
    existing_genre_ids = @fiction.genres.ids

    genres_to_add = fiction_genres_ids - existing_genre_ids
    genres_to_remove = existing_genre_ids - fiction_genres_ids

    genres_to_add.each { |genre_id| @fiction.fiction_genres.create(genre_id:) }
    genres_to_remove.each { |genre_id| @fiction.fiction_genres.find_by(genre_id:).destroy }
  end

  def other
    fiction_exclusions_query.merge(fiction_with_max_created_at_query)
  end

  def other_mobile
    fiction_exclusions_query_mobile.merge(fiction_with_max_created_at_query)
  end

  def most_reads
    Rails.cache.fetch('most_reads', expires_in: 12.hours) do
      fiction_with_total_views_query.limit(5)
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
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params)
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
      :status, :title, :translator, :total_chapters, :user_id
    )
  end

  def next_chapter
    first_chapter = @fiction.chapters.order(:number).first

    return first_chapter unless @reading_progress.present?

    chapter = @reading_progress.chapter

    chapter.fiction.chapters.where(
      'number > ? OR (number = ? AND created_at > ?)', chapter.number, chapter.number, chapter.created_at
    ).order(:number).first || first_chapter
  end

  def set_fiction
    @fiction = @commentable = Fiction.find(params[:id])
  end

  def split_chapter_list
    fiction_chapters = @fiction.chapters.order(number: :desc, created_at: :desc)
    next_chapter_index = fiction_chapters.index(@next_chapter)

    return unless next_chapter_index

    @before_next_chapter = fiction_chapters[0...next_chapter_index + 1]
    @after_next_chapter = fiction_chapters[next_chapter_index + 1..]
  end

  def reading_progress_vars
    @reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: current_user&.id)
    @next_chapter = next_chapter
    split_chapter_list
  end

  def refresh_list
    turbo_stream.update(
      'fictions-list',
      partial: 'users/dashboard/fictions',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end

  def setup_sidebar_vars
    @fictions_size = fiction_list.count
    @user_publications = current_user.publications.order(created_at: :desc)
  end

  def refresh_sidebar
    turbo_stream.update('default-sidebar', partial: 'users/dashboard/sidebar')
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.fictions.include?(@fiction)
  end
end
