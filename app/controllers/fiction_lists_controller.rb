# frozen_string_literal: true

# Paginated fiction browse lists (alphabetical index with filters and Turbo updates).
class FictionListsController < ApplicationController
  include Fictions::CatalogIncludeEighteenPreference

  helper Fictions::ListPaginationHelper

  before_action :pokemon_appearance, only: [:alphabetical]
  before_action :resolve_catalog_include_eighteen, only: [:alphabetical]

  def alphabetical
    @pagy, @fictions = paginated_fictions

    if turbo_frame_request_id == 'fiction-list-page'
      return render partial: 'fiction_lists/dynamic_content',
                    locals: { fictions: @fictions, pagy: @pagy }
    end

    respond_to do |format|
      format.html
      format.turbo_stream { render_fictions_list }
    end
  end

  private

  def paginated_fictions
    base_scope = catalog_include_eighteen? ? Fiction.all : Fiction.not_eighteen

    pagy(
      FictionListQueryBuilder.new(
        base_scope,
        Fictions::ListFilters.permit_for_query(params)
      ).call,
      limit: 20
    )
  end

  def render_fictions_list
    render turbo_stream: turbo_stream_list_refresh(
      turbo_stream.update(
        'fiction-list-page',
        partial: 'fiction_lists/dynamic_content',
        locals: {
          fictions: @fictions,
          pagy: @pagy
        }
      )
    )
  end
end
