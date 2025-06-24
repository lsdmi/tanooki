# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement

  def alphabetical
    @pagy, @fictions = paginated_fictions

    respond_to do |format|
      format.html
      format.turbo_stream { render_fictions_list }
    end
  end

  private

  def paginated_fictions
    pagy(
      FictionListQueryBuilder.new(
        Fiction.all,
        params.permit(:'genre-radio')
      ).call,
      limit: 8
    )
  end

  def render_fictions_list
    render turbo_stream: turbo_stream.update(
      'fiction-list-page',
      partial: 'dynamic_content',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end
end
