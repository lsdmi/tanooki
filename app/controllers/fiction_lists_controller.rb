# frozen_string_literal: true

# Paginated fiction browse lists (alphabetical index with filters and Turbo updates).
class FictionListsController < ApplicationController
  include Fictions::CatalogIncludeEighteenPreference
  include Fictions::GuestAlphabeticalCaching

  helper Fictions::ListPaginationHelper
  helper Fictions::ShowCacheHelper

  before_action :pokemon_appearance, only: [:alphabetical], unless: :guest_alphabetical_request?
  before_action :resolve_catalog_include_eighteen, only: [:alphabetical]
  after_action :set_guest_alphabetical_cache_headers, only: :alphabetical

  def alphabetical
    return if serve_fresh_guest_alphabetical?

    @pagy, @fictions = paginated_fictions
    @explicit_hidden_genre = explicit_hidden_genre?

    if turbo_frame_request_id == 'fiction-list-page'
      return render partial: 'fiction_lists/dynamic_content', locals: list_locals
    end

    respond_to do |format|
      format.html
      format.turbo_stream { render_fictions_list }
    end
  end

  private

  def catalog_query_params
    Fictions::ListFilters.permit_for_query(params).merge(
      q: params[:q].is_a?(String) ? params[:q] : nil,
      sort: FictionListQueryBuilder.normalize_sort(params[:sort])
    )
  end

  def paginated_fictions
    pagy(
      FictionListQueryBuilder.new(catalog_scope, catalog_query_params).call,
      limit: 24
    )
  end

  def catalog_scope
    base = catalog_include_eighteen? ? Fiction.all : Fiction.not_eighteen
    current_content_filter.apply(base)
  end

  def explicit_hidden_genre?
    genre_id = params[:genre].to_i
    genre_id.positive? && current_content_filter.hidden_genre_ids.include?(genre_id)
  end

  def list_locals
    {
      fictions: @fictions,
      pagy: @pagy,
      explicit_hidden_genre: @explicit_hidden_genre,
      content_filter_notice: true
    }
  end

  def render_fictions_list
    render turbo_stream: turbo_stream_list_refresh(
      turbo_stream.update(
        'fiction-list-page',
        partial: 'fiction_lists/dynamic_content',
        locals: list_locals
      )
    )
  end
end
