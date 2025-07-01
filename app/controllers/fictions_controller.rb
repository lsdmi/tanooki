# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery
  include LibraryHelper

  before_action :authenticate_user!, except: %i[index show toggle_order details]
  before_action :set_fiction, only: %i[show edit update destroy toggle_order]
  before_action :set_genres, only: %i[new create edit update]
  before_action :load_advertisement, :track_visit, only: :show
  before_action :authorize_fiction, only: %i[edit update destroy]
  before_action :authorize_fiction_creation, only: %i[new create]

  def index
    @index_presenter = FictionIndexPresenter.new(params)
    respond_to do |format|
      format.html
      format.turbo_stream { render_filtered_fictions }
    end
  end

  def show
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, params)
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
      render :new, status: :unprocessable_entity
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
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    FictionDestroyService.new(@fiction, current_user).call
    @pagy, @fictions = paginate_fictions
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  def toggle_order
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, toggle_order_params)
    render turbo_stream: [update_sorted_chapters]
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
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def authorize_fiction
    policy = FictionPolicy.new(current_user, @fiction)
    redirect_to root_path unless policy.edit?
  end

  def authorize_fiction_creation
    policy = FictionPolicy.new(current_user, nil)
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
