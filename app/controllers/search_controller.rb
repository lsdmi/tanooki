# frozen_string_literal: true

class SearchController < ApplicationController
  def index
    redirect_to root_path unless params[:search]

    @results = Publication.search(
      params[:search],
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '30d', decay: 0.9 } }
    )

    @tag = Tag.find_by(name: params[:search])
    @tag ? set_tag_logic : set_search_logic
  end

  private

  def set_tag_logic
    return if @results.size < 6

    count_without_main = @results.count - 5
    num_to_add = 3 - (count_without_main % 3)
    excluded_ids = @results.to_a.pluck(:id)

    @results = (
      @results.to_a +
      Publication.all.order(created_at: :desc).where.not(id: excluded_ids).first(num_to_add)
    )
  end

  def set_search_logic
    @advertisement = Advertisement.enabled.sample
  end
end
