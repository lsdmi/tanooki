# frozen_string_literal: true

class FictionsController < ApplicationController
  include FictionQuery
  include Library::ReadingStateHelper

  AD_EXCLUDED_SLUGS = %w[
    lehendarnyi-skulptor-misiachnoho-svitla
  ].freeze

  before_action :authenticate_user!, except: %i[index show toggle_order details chapter_section]
  before_action :set_fiction, only: %i[show edit update destroy toggle_order chapter_section]
  before_action :set_genres, only: %i[new create edit update]
  before_action :load_advertisement, only: :show, unless: :ads_disabled_for_current_page?
  before_action :track_visit, only: :show
  before_action :authorize_fiction, only: %i[edit update destroy]
  before_action :authorize_fiction_creation, only: %i[new create]
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @index_presenter = FictionIndexPresenter.new(params)
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
        scanlator_ids: fiction_params[:scanlator_ids],
        user: current_user
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
        scanlator_ids: fiction_params[:scanlator_ids],
        user: current_user
      ).call
      redirect_to @fiction, notice: 'Твір оновлено.'
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    FictionDestroyService.new(@fiction, current_user).call
    @pagy, @fictions = paginate_fictions
    render turbo_stream: [refresh_list, refresh_sweetalert]
  end

  def toggle_order
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, toggle_order_params)
    render turbo_stream: sorted_chapters_turbo_streams
  end

  def chapter_section
    order = params[:order].presence&.to_sym || :desc
    @section_chapters = Fictions::ChapterSectionLoader.new(
      fiction: @fiction,
      viewer: current_user,
      section_key: params[:section],
      order: order,
      chapter_ids: params[:chapter_ids]
    ).call

    render partial: 'fictions/chapter_section_items',
           layout: false,
           locals: chapter_section_locals(order)
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
    @fiction = @commentable = Fiction.includes(:genres, :scanlators, cover_attachment: :blob).find(params[:id])
    @commentable = @fiction
  end

  def ads_disabled_for_current_page?
    @fiction&.slug.in?(AD_EXCLUDED_SLUGS) || super
  end

  def chapter_from_section_params
    return nil if params[:current_chapter_id].blank?

    Chapter.find_by(id: params[:current_chapter_id])
  end

  def chapter_section_locals(_order)
    {
      chapters: @section_chapters,
      compact: ActiveModel::Type::Boolean.new.cast(params[:compact]),
      current_chapter: chapter_from_section_params
    }
  end

  def set_genres
    @genres = Genre.order(:name)
  end

  def fiction_params
    params.require(:fiction).permit(
      :alternative_title, :author, :cover, :description, :english_title, :origin,
      :status, :title, :total_chapters, :short_description, :banner, :adult_content, genre_ids: [], scanlator_ids: []
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

  def render_sorted_chapters
    render turbo_stream: sorted_chapters_turbo_streams
  end

  def sorted_chapters_turbo_streams
    locals = @show_presenter.sorted_chapters_locals
    if chapters_sort_from_chapter_reader?
      frame_dom_id = 'sort-chapters-mobile'
      locals = locals.merge(
        compact: true,
        toggle_order_button_id: 'toggle-fictions-order-drawer',
        drawer_toc: true,
        current_chapter: current_chapter_from_chapter_reader_referer
      )
    else
      frame_dom_id = 'sort-chapters'
    end
    [turbo_stream.update(frame_dom_id, partial: 'chapters', locals: locals)]
  end

  def chapters_sort_from_chapter_reader?
    ref = request.referer
    return false if ref.blank?

    URI.parse(ref).path.match?(%r{\A/chapters/})
  rescue URI::InvalidURIError
    false
  end

  def current_chapter_from_chapter_reader_referer
    ref = request.referer
    return nil if ref.blank?

    chapter_id = URI.parse(ref).path[%r{\A/chapters/([^/]+)\z}, 1]
    return nil if chapter_id.blank?

    Chapter.find_by(id: chapter_id)
  rescue URI::InvalidURIError
    nil
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
    if request.referer == alphabetical_fictions_url || request.referer&.include?('/bookshelves/')
      'fiction_lists/fiction_details'
    else
      'fictions/fiction_details'
    end
  end
end
