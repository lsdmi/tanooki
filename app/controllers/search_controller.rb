# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :load_advertisement
  before_action :pokemon_appearance, only: [:index]

  def index
    return redirect_to root_path if transformed_param.nil?

    case params[:filter]
    when 'fiction'
      @pagy_fictions, @fictions = pagy_searchkick_for(fiction_search, limit: 24)
      @results = []
      @videos = []
    when 'blog'
      @pagy_results, @results = pagy_searchkick_for(publication_search, limit: 7)
      @fictions = []
      @videos = []
    when 'video'
      @pagy_videos, @videos = pagy_searchkick_for(video_search, limit: 6)
      @fictions = []
      @results = []
    else
      @pagy_fictions, @fictions = pagy_searchkick_for(fiction_search, limit: 12)
      @pagy_results, @results = pagy_searchkick_for(publication_search, limit: 7)
      @pagy_videos, @videos = pagy_searchkick_for(video_search, limit: 3)
    end

    # Handle turbo frame requests for pagination
    if turbo_frame_request_id.present?
      case turbo_frame_request_id
      when 'fictions-section'
        return render partial: 'search/fictions_section', locals: { fictions: @fictions, pagy_fictions: @pagy_fictions }
      when 'results-section'
        return render partial: 'search/results_section', locals: { results: @results, pagy_results: @pagy_results }
      when 'videos-section'
        return render partial: 'search/videos_section', locals: { videos: @videos, pagy_videos: @pagy_videos }
      end
    end

    respond_to do |format|
      format.html { render 'index' }
      format.turbo_stream do
        # Determine which section to update based on the section parameter
        case params[:section]
        when 'fictions'
          render turbo_stream: turbo_stream.replace('fictions-section', partial: 'search/fictions_section',
                                                                        locals: { fictions: @fictions, pagy_fictions: @pagy_fictions })
        when 'results'
          render turbo_stream: turbo_stream.replace('results-section', partial: 'search/results_section',
                                                                       locals: { results: @results, pagy_results: @pagy_results })
        when 'videos'
          render turbo_stream: turbo_stream.replace('videos-section', partial: 'search/videos_section',
                                                                      locals: { videos: @videos, pagy_videos: @pagy_videos })
        end
      end
    end
  end

  private

  def transformed_param
    return nil unless params[:search].present?

    params[:search] = Array(params[:search])
  end

  def fiction_search
    Fiction.pagy_searchkick(
      params[:search],
      fields: ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators']
    ).includes(%i[genres scanlators])
  end

  def publication_search
    Publication.pagy_searchkick(
      params[:search],
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } }
    ).includes(%i[tags rich_text_description])
  end

  def video_search
    YoutubeVideo.pagy_searchkick(
      params[:search],
      fields: ['title^2', 'description', 'tags'],
      boost_by_recency: { published_at: { scale: '7d', decay: 0.9 } }
    ).includes(:youtube_channel)
  end

  OPENSEARCH_CONNECTION_ERRORS = [
    Faraday::Error,
    Errno::ECONNREFUSED,
    SocketError,
    Timeout::Error
  ].freeze

  def pagy_searchkick_for(search_args, limit:)
    pagy_searchkick(search_args, limit: limit)
  rescue *OPENSEARCH_CONNECTION_ERRORS => e
    Rails.logger.warn("[search] OpenSearch unavailable: #{e.class}: #{e.message}")
    @search_unavailable = true
    [empty_search_pagy(limit), []]
  end

  def empty_search_pagy(limit)
    Pagy.new(count: 0, page: params[:page] || 1, limit: limit)
  end
end
