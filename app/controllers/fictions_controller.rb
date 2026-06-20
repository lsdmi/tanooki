# frozen_string_literal: true

# Fiction catalog: browse, create, edit, and manage translator works.
class FictionsController < ApplicationController
  helper Chapters::ChapterDrawerHelper,
         Chapters::PresentationHelper,
         Library::ChapterCatalogHelper,
         Library::ReadingStateHelper,
         Scanlators::SelectOptionsHelper
  include FictionQuery
  include Fictions::ChapterSectionRendering
  include Fictions::DashboardListing
  include Fictions::FictionPersistence
  include Fictions::TurboStreamResponses

  AD_EXCLUDED_SLUGS = %w[
    lehendarnyi-skulptor-misiachnoho-svitla
  ].freeze

  before_action :authenticate_user!, except: %i[index show toggle_order details chapter_section]
  before_action :set_fiction, only: %i[show edit update destroy toggle_order chapter_section]
  before_action :set_genres, only: %i[new create edit update]
  before_action :load_advertisement, only: :show
  before_action :track_visit, only: :show
  before_action :authorize_fiction, only: %i[edit update destroy]
  before_action :authorize_fiction_creation, only: %i[new create]
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @index_presenter = FictionIndexPresenter.new
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
    persist_fiction(Fictions::SyncAssociations, :new, t('fictions.notices.create_success'))
  end

  def update
    @fiction = Fiction.find(params[:id])
    persist_fiction(Fictions::SyncAssociationsAndStatus, :edit, t('fictions.notices.update_success'))
  end

  def destroy
    Fictions::DestroyOrUnlink.new(@fiction, current_user).call
    @pagy, @fictions = paginate_fictions
    render turbo_stream: turbo_stream_destroy_success(refresh_list, t('fictions.notices.destroy_success'))
  end

  def toggle_order
    @show_presenter = FictionShowPresenter.new(@fiction, current_user, toggle_order_params)
    render turbo_stream: sorted_chapters_turbo_streams
  end

  def chapter_section
    order = params[:order].presence&.to_sym || :desc
    @section_chapters = load_chapter_section(order)
    render_chapter_section_items(order)
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

  def set_genres
    @genres = Genre.order(:name)
  end

  def authorize_fiction
    policy = Fictions::Authorization.new(current_user, @fiction)
    redirect_to root_path unless policy.edit?
  end

  def authorize_fiction_creation
    policy = Fictions::Authorization.new(current_user, nil)
    redirect_to new_scanlator_path unless policy.create?
  end
end
