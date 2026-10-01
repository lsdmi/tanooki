# frozen_string_literal: true

# Site-wide search across fictions, publications, and videos.
class SearchController < ApplicationController
  rate_limit to: 30, within: 1.minute, by: -> { client_ip }, only: :index
  # Full-page searches are what crawlers request; tab and pagination fetches inside the page are Turbo requests.
  rate_limit to: 10, within: 1.minute, by: -> { client_ip }, name: 'page', only: :index,
             unless: -> { turbo_frame_request_id.present? || request.format.turbo_stream? }

  helper Pagination::SearchIndexHelper

  include Search::IndexQuery

  before_action :pokemon_appearance, only: [:index]

  def index
    return redirect_to root_path if transformed_param.nil?

    load_search_results
    return render_search_turbo_frame if turbo_frame_request_id.present?

    respond_to do |format|
      format.html { render 'index' }
      format.turbo_stream { render_search_turbo_stream }
    end
  end
end
