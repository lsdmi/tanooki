# frozen_string_literal: true

class SearchController < ApplicationController
  before_action :load_advertisement
  before_action :pokemon_appearance, only: [:index]

  VIDEOS_PER_PAGE = 4
  VIDEOS_FILTER_PER_PAGE = 8

  OPENSEARCH_CONNECTION_ERRORS = [
    Faraday::Error,
    Errno::ECONNREFUSED,
    SocketError,
    Timeout::Error,
    OpenSearch::Transport::Transport::Error
  ].freeze

  def index
    return redirect_to root_path if transformed_param.nil?

    @pagy_fictions, fiction_records = pagy_searchkick_for(fiction_search, limit: fiction_per_page)
    @pagy_results, publication_records = pagy_searchkick_for(publication_search, limit: publication_per_page)
    @pagy_videos, video_records = pagy_searchkick_for(video_search, limit: video_per_page)

    @fictions = show_fictions? ? fiction_records : []
    @results = show_publications? ? publication_records : []
    @videos = show_videos? ? video_records : []
    @trending_tag_labels = trending_tag_labels_for_sidebar
    @trending_tag_counts = search_tag_counts(@trending_tag_labels)

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
    return nil if params[:search].blank?

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
    ).includes(:rich_text_description, :cover_attachment)
  end

  def video_search
    YoutubeVideo.pagy_searchkick(
      params[:search],
      fields: ['title^2', 'description', 'tags'],
      boost_by_recency: { published_at: { scale: '7d', decay: 0.9 } }
    )
  end

  def pagy_searchkick_for(search_args, limit:)
    pagy_searchkick(search_args, limit: limit, limit_extra: false)
  rescue *OPENSEARCH_CONNECTION_ERRORS => e
    Rails.logger.warn("[search] OpenSearch unavailable: #{e.class}: #{e.message}")
    @search_unavailable = true
    [empty_search_pagy(limit), []]
  end

  def empty_search_pagy(limit)
    Pagy.new(count: 0, page: params[:page] || 1, limit: [limit, 1].max)
  end

  def fiction_per_page
    case params[:filter]
    when 'fiction' then 24
    when 'blog', 'video' then 1
    else 12
    end
  end

  def publication_per_page
    return 1 if params[:filter].in?(%w[fiction video])

    7
  end

  def video_per_page
    case params[:filter]
    when 'video' then VIDEOS_FILTER_PER_PAGE
    when 'fiction', 'blog' then 1
    else VIDEOS_PER_PAGE
    end
  end

  def show_fictions?
    all_filter? || params[:filter] == 'fiction'
  end

  def show_publications?
    all_filter? || params[:filter] == 'blog'
  end

  def show_videos?
    all_filter? || params[:filter] == 'video'
  end

  def all_filter?
    %w[fiction blog video].exclude?(params[:filter])
  end

  def trending_tag_labels_for_sidebar
    trending_tags.filter_map { |tag| tag[:name].presence }
  end
end
