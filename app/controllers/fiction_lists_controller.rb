# frozen_string_literal: true

# Paginated fiction browse lists (alphabetical index with filters and Turbo updates).
class FictionListsController < ApplicationController
  helper Fictions::ListPaginationHelper

  before_action :load_advertisement
  before_action :pokemon_appearance, only: [:alphabetical]

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
    base_scope = params[:adult_content].present? ? Fiction.all : Fiction.safe_content

    pagy(
      FictionListQueryBuilder.new(
        base_scope,
        Fictions::ListFilters.permit_for_query(params)
      ).call,
      limit: 20
    )
  end

  def render_fictions_list
    render turbo_stream: turbo_stream.update(
      'fiction-list-page',
      partial: 'fiction_lists/dynamic_content',
      locals: {
        fictions: @fictions,
        pagy: @pagy
      }
    )
  end
end
