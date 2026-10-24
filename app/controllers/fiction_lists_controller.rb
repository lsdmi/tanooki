# frozen_string_literal: true

# Paginated fiction browse lists (alphabetical index with filters and Turbo updates).
class FictionListsController < ApplicationController
  include Fictions::CatalogIncludeEighteenPreference

  helper Fictions::ListPaginationHelper

  before_action :pokemon_appearance, only: [:alphabetical]
  before_action :resolve_catalog_include_eighteen, only: [:alphabetical]

  def alphabetical
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

  def paginated_fictions
    pagy(
      FictionListQueryBuilder.new(catalog_scope, Fictions::ListFilters.permit_for_query(params)).call,
      limit: 20
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
    { fictions: @fictions, pagy: @pagy, explicit_hidden_genre: @explicit_hidden_genre, content_filter_notice: true }
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
