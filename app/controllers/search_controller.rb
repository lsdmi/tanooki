# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    return redirect_to root_path if transformed_param.nil?

    @results = publications
    @fictions = fictions
    @videos = videos

    set_tag_logic

    respond_to do |format|
      format.html { render 'index' }
      format.turbo_stream { render turbo_stream: replace_search_page }
    end
  end

  private

  def transformed_param
    return nil unless params[:search].present?

    params[:search] = Array(params[:search])
  end

  def replace_search_page
    turbo_stream.replace(
      'search-page', partial: 'search_page', locals: { results: @results, fictions: @fictions, videos: @videos }
    )
  end

  def set_tag_logic
    @tag = Tag.find_by(name: params[:search])

    return if @tag.nil?

    Searchkick.client.ping ? set_tag_logic_es : set_tag_logic_no_es
  end

  def set_tag_logic_es
    return if @results.size < 6

    count_without_main = @results.count - 5
    num_to_add = 3 - (count_without_main % 3)
    excluded_ids = @results.to_a.pluck(:id)

    @results = (
      @results.to_a +
      Publication.includes([{ cover_attachment: :blob }])
                 .order(created_at: :desc).where.not(id: excluded_ids).first(num_to_add)
    )
  end

  def set_tag_logic_no_es
    @results = SearchService.publications(params[:search])
  end

  def publications
    if Searchkick.client.ping
      Publication.search(
        params[:search],
        fields: ['tags^10', 'title^5', 'description'],
        boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } }
      ).includes([{ cover_attachment: :blob }, :rich_text_description])
    else
      SearchService.publications(params[:search])
    end
  end

  def fictions
    if Searchkick.client.ping
      Fiction.search(
        params[:search],
        fields: ['title^2', 'alternative_title', 'author', 'english_title', 'scanlators']
      ).includes([{ cover_attachment: :blob }, :genres, :scanlators])
    else
      SearchService.fictions(params[:search])
    end
  end

  def videos
    if Searchkick.client.ping
      YoutubeVideo.search(
        params[:search],
        fields: ['title^2', 'description', 'tags']
      ).includes(:rich_text_description, :youtube_channel)
    else
      SearchService.videos(params[:search])
    end
  end
end
