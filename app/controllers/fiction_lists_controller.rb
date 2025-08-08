# frozen_string_literal: true

class FictionListsController < ApplicationController
  before_action :load_advertisement
  before_action :pokemon_appearance, only: [:alphabetical]

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
        params.permit(:genre, :only_new, :longreads, :finished)
      ).call,
      limit: 20
    )
  end

  def render_fictions_list
    render turbo_stream: turbo_stream.update(
      'fiction-list-page',
      partial: 'fiction_lists/dynamic_content',
      locals: { fictions: @fictions, pagy: @pagy }
    )
  end
end
