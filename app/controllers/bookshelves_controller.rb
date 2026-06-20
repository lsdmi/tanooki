# frozen_string_literal: true

# User-curated fiction lists (bookshelves) for browsing and managing collections.
class BookshelvesController < ApplicationController
  helper Fictions::ListPaginationHelper

  before_action :authenticate_user!, except: %i[index show]
  before_action :set_bookshelf, only: %i[show edit update destroy]
  before_action :load_selected_fictions, only: %i[new create edit update]
  before_action :track_visit, only: :show

  def index; end

  def show
    @pagy, @fictions = pagy(@bookshelf.fictions.includes(:cover_attachment, :genres), limit: 20)
    @advertisement = Advertisement.enabled.includes(:cover_attachment, :poster_attachment).sample

    return unless turbo_frame_request_id == 'fiction-list-page'

    render partial: 'fiction_lists/dynamic_content',
           locals: {
             fictions: @fictions,
             pagy: @pagy
           }
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
    render turbo_stream: refresh_list
  end

  private

  def set_bookshelf
    @bookshelf = if action_name == 'show'
                   Bookshelf.by_sqid(params[:sqid]).first!
                 else
                   current_user.bookshelves.by_sqid(params[:sqid]).first!
                 end
  end

  def bookshelf_params
    params.expect(bookshelf: [:title, :description, { fiction_ids: [] }])
  end

  def sync_bookshelf_fictions
    Bookshelves::SyncFictions.call(
      bookshelf: @bookshelf,
      fiction_ids: submitted_fiction_ids
    )
  end

  def submitted_fiction_ids
    return [] unless params[:bookshelf]&.key?(:fiction_ids)

    Array(params.dig(:bookshelf, :fiction_ids)).compact_blank
  end

  def load_selected_fictions
    ids = if params[:bookshelf]&.key?(:fiction_ids)
            Array(params.dig(:bookshelf, :fiction_ids)).compact_blank
          elsif @bookshelf&.persisted?
            @bookshelf.fictions.pluck(:id)
          else
            []
          end

    @selected_fictions = ids.any? ? Fiction.where(id: ids).order(:title) : Fiction.none
  end

  def refresh_list
    turbo_stream.update(
      'bookshelves-list',
      partial: 'studio/tabs/bookshelves',
      locals: { bookshelves: @bookshelves }
    )
  end
end
