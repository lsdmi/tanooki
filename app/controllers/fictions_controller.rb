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

  def create
    @fiction = Fiction.new(fiction_params)
    if @fiction.save
      handle_fiction_creation
      redirect_to @fiction, notice: 'Твір створено.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @fiction.update(fiction_params)
      handle_fiction_update
      redirect_to @fiction, notice: 'Твір оновлено.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    FictionDestroyService.new(@fiction, current_user).call
    @pagy, @fictions = paginate_fictions
    setup_paginator
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  def toggle_order
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, toggle_order_params)
    render turbo_stream: [update_sorted_chapters]
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
      :status, :title, :total_chapters, genre_ids: [], scanlator_ids: []
    )
  end

  def ordered_fiction_list
    current_user.admin? ? fiction_all_ordered_by_latest_chapter : dashboard_fiction_list
  end

  def verify_permissions
    redirect_to root_path unless current_user.admin? || current_user.fictions.include?(@fiction)
  end

  def verify_create_permissions
    redirect_to new_scanlator_path unless current_user.admin? || current_user.scanlators.any?
  end

  def handle_fiction_creation
    FictionGenresManager.new(fiction_params[:genre_ids], @fiction).operate
    FictionScanlatorsManager.new(fiction_params[:scanlator_ids], @fiction).operate
  end

  def handle_fiction_update
    handle_fiction_creation
    update_fiction_status
  end

  def update_fiction_status
    new_status = FictionStatusTracker.new(@fiction).call
    @fiction.update_column(:status, new_status)
  end

  def paginate_fictions
    pagy(
      ordered_fiction_list,
      items: 8,
      request_path: readings_path,
      page: fiction_page || 1
    )
  end

  def setup_paginator
    fiction_paginator = FictionPaginator.new(@pagy, @fictions, params, current_user)
    fiction_paginator.call
    @paginators = fiction_paginator.initiate
  end

  def fiction_page
    (params[:page].to_i - 1) if Fiction.count <= (params[:page].to_i * 8) - 8
  end

  def render_filtered_fictions
    render turbo_stream: turbo_stream.replace(
      'filtered-fictions',
      partial: 'other_section',
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
      locals: { fictions: @fictions, pagy: @pagy, paginators: @paginators }
    )
  end
end
