# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :require_authentication, except: %i[index show toggle_order details]
  before_action :set_fiction, only: %i[show edit update destroy toggle_order update_reading_status]
  before_action :set_genres, only: %i[new create edit update]
  before_action :load_advertisement, :track_visit, only: :show
  before_action :authorize_fiction, only: %i[edit update destroy]
  before_action :authorize_fiction_creation, only: %i[new create]
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @index_presenter = FictionIndexPresenter.new(params)
    respond_to do |format|
      format.html
      format.turbo_stream { render_filtered_fictions }
    end
  end

  def show
    @show_presenter = FictionShowPresenter.new(@fiction, Current.user, params)
    respond_to do |format|
      format.html
      format.turbo_stream { render_sorted_chapters }
    end
  end

  def new
    @fiction = Fiction.new
  end

  def edit; end

  def create
    @fiction = Fiction.new
    form = FictionForm.new(fiction: @fiction, params: fiction_params)
    if form.save
      FictionCreator.new(
        @fiction,
        genre_ids: fiction_params[:genre_ids],
        scanlator_ids: fiction_params[:scanlator_ids]
      ).call
      redirect_to @fiction, notice: 'Твір створено.'
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    @fiction = Fiction.find(params[:id])
    form = FictionForm.new(fiction: @fiction, params: fiction_params)
    if form.save
      FictionUpdater.new(
        @fiction,
        genre_ids: fiction_params[:genre_ids],
        scanlator_ids: fiction_params[:scanlator_ids]
      ).call
      redirect_to @fiction, notice: 'Твір оновлено.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    FictionDestroyService.new(@fiction, Current.user).call
    @pagy, @fictions = paginate_fictions
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  def toggle_order
    @show_presenter = FictionShowPresenter.new(@fiction, Current.user, toggle_order_params)
    render turbo_stream: [update_sorted_chapters]
  end

  def update_reading_status
    reading_progress = ReadingProgress.find_by(fiction_id: @fiction.id, user_id: Current.user.id)

    if reading_progress
      new_status = params[:status]&.to_sym
      ReadingProgressStatusService.new(reading_progress, new_status, Current.user).call
    else
      first_chapter = ordered_chapters(@fiction).first
      if first_chapter
        ReadingProgress.create!(
          fiction_id: @fiction.id,
          user_id: Current.user.id,
          chapter_id: first_chapter.id,
          status: params[:status]&.to_sym || :active
        )
      end
    end

    @show_presenter = FictionShowPresenter.new(@fiction, Current.user, params)

    render turbo_stream: turbo_stream.update(
      'fiction-reading-status',
      partial: 'fictions/reading_status_controls',
      locals: {
        fiction: @fiction,
        show_presenter: @show_presenter
      }
    )
  end

  def details
    @fiction = Fiction.find(params[:id])
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          'fiction_details',
          partial: details_partial,
          locals: { fiction: @fiction }
        )
      end
    end
  end

  private

  def set_fiction
    @fiction = @commentable = Fiction.find(params[:id])
  end

  def set_genres
    @genres = Genre.order(:name)
  end

  def fiction_params
    params.require(:fiction).permit(
      :alternative_title, :author, :cover, :description, :english_title, :origin,
      :status, :title, :total_chapters, :short_description, :banner, genre_ids: [], scanlator_ids: []
    )
  end

  def ordered_fiction_list
    Current.user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def authorize_fiction
    policy = FictionPolicy.new(Current.user, @fiction)
    redirect_to root_path unless policy.edit?
  end

  def authorize_fiction_creation
    policy = FictionPolicy.new(Current.user, nil)
    redirect_to new_scanlator_path unless policy.create?
  end

  def paginate_fictions
    pagy(
      ordered_fiction_list,
      limit: 6,
      request_path: readings_path,
      page: fiction_page || 1
    )
  end

  def fiction_page
    (params[:page].to_i - 1) if Fiction.count <= (params[:page].to_i * 8) - 8
  end

  def render_filtered_fictions
    render turbo_stream: turbo_stream.replace(
      'filtered-fictions',
      partial: 'filtered_fiction_list',
      locals: @index_presenter.filtered_fictions_locals
    )
  end

  def render_sorted_chapters
    render turbo_stream: turbo_stream.update(
      'sort-chapters',
      partial: 'chapters',
      locals: @show_presenter.sorted_chapters_locals
    )
  end

  def update_sorted_chapters
    turbo_stream.update(
      'sort-chapters',
      partial: 'chapters',
      locals: @show_presenter.sorted_chapters_locals
    )
  end

  def toggle_order_params
    params.merge(order: params[:order].to_sym == :desc ? :asc : :desc)
  end

  def refresh_list
    turbo_stream.update(
      'fictions-list',
      partial: 'users/dashboard/fictions',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end

  def details_partial
    request.referer == alphabetical_fictions_url ? 'fiction_lists/fiction_details' : 'fictions/fiction_details'
  end
end
