# frozen_string_literal: true

# User-curated fiction lists (bookshelves) for browsing and managing collections.
class BookshelvesController < ApplicationController
  include Bookshelves::FormActions
  include Bookshelves::GuestHubCaching

  helper Fictions::ListPaginationHelper, Ui::StrokeIconHelper

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_bookshelf, only: %i[show edit update destroy]
  before_action :load_selected_fictions, only: %i[new create edit update]
  before_action :track_bookshelf_visit, only: :show
  after_action :set_guest_hub_cache_headers, only: :index

  def index
    return if serve_fresh_guest_hub?

    prepare_hub
    return unless turbo_frame_request_id == 'hub-recent-page'

    render partial: 'bookshelves/hub_recent_list', locals: { entries: @recent, pagy: @pagy }
  end

  def show
    prepare_bookshelf_fictions
    return unless turbo_frame_request_id == 'fiction-list-page'

    render partial: 'bookshelves/fiction_list', locals: bookshelf_list_locals
  end

  def fiction_options
    render json: Bookshelves::FictionSearch.call(query: params[:q])
  end

  def new
    @bookshelf = current_user.bookshelves.build
  end

  def edit
    @bookshelf.fiction_ids = @bookshelf.fictions.pluck(:id)
  end

  def create
    @bookshelf = current_user.bookshelves.build(bookshelf_params)
    if @bookshelf.save
      sync_bookshelf_fictions
      redirect_to studio_index_path(tab: 'bookshelves'), notice: t('bookshelves.notices.create_success')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @bookshelf.update(bookshelf_params)
      sync_bookshelf_fictions
      redirect_to studio_index_path(tab: 'bookshelves'), notice: t('bookshelves.notices.update_success')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @bookshelf.destroy
    @bookshelves = current_user.bookshelves.ordered
    render turbo_stream: turbo_stream_destroy_success(refresh_list, t('bookshelves.notices.destroy_success'))
  end

  private

  def prepare_hub
    hub = { viewer: current_user, filter: current_content_filter }
    @popular = Bookshelves::HubPreview.popular(**hub) unless recent_hub_frame?
    @pagy, recent = pagy(Bookshelves::HubPreview.recent_scope(exclude_ids: hub_exclude_ids(hub), **hub),
                         limit: Bookshelves::HubPreview::RECENT_PER_PAGE)
    @recent = Bookshelves::HubPreview.decorate(recent, **hub)
  end

  def recent_hub_frame?
    turbo_frame_request_id == 'hub-recent-page'
  end

  def hub_exclude_ids(hub)
    return Bookshelves::HubPreview.popular_ids(**hub) if recent_hub_frame?

    @popular.map { |entry| entry.bookshelf.id }
  end

  def prepare_bookshelf_fictions
    relation, @hidden_fiction_count, @content_filter_fingerprint = Bookshelves::VisibleFictions.call(
      bookshelf: @bookshelf, viewer: current_user, filter: current_content_filter
    )
    @header_covers = relation.joins(:cover_attachment).includes(:cover_attachment).limit(5)
    @pagy, @fictions = pagy(relation.includes(:genres, :cover_attachment), limit: 24)
  end

  def bookshelf_list_locals
    {
      bookshelf: @bookshelf,
      fictions: @fictions,
      pagy: @pagy,
      hidden_fiction_count: @hidden_fiction_count,
      content_filter_fingerprint: @content_filter_fingerprint
    }
  end

  def set_bookshelf
    @bookshelf = if action_name == 'show'
                   Bookshelf.by_sqid(params[:sqid]).first!
                 else
                   current_user.bookshelves.by_sqid(params[:sqid]).first!
                 end
  end

  def track_bookshelf_visit
    track_visit(@bookshelf)
  end

  def bookshelf_params
    params.expect(bookshelf: [:title, :description, { fiction_ids: [] }])
  end
end
