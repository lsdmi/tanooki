# frozen_string_literal: true

# Site-wide search across fictions, publications, and videos.
class SearchController < ApplicationController
  include Search::IndexQuery

  before_action :load_advertisement
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
