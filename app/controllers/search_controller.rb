# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    return redirect_to root_path if params[:search].nil?

    @results = publications
    @fictions = fictions

    @tag = Tag.find_by(name: params[:search])
    @tag ? set_tag_logic : set_search_logic
  end

  private

  def set_tag_logic
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
        fields: ['title^2', 'alternative_title', 'english_title']
      ).includes([{ cover_attachment: :blob }, :chapters, :genres])
    else
      SearchService.fictions(params[:search])
    end
  end

  def set_search_logic
    @videos = videos
  end
end
