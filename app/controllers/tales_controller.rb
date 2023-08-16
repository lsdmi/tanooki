# frozen_string_literal: true

class TalesController < ApplicationController
  before_action :set_tale, :track_visit
  before_action :load_advertisement, only: :show

  def show
    @more_tales = more_tails
    @comments = @publication.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @videos = videos
  end

  private

  def more_tails
    return base_search.excluding(@publication).first(6) if base_search.size > 6

    (
      base_search.to_a + Publication.all.includes([{ cover_attachment: :blob }]).order(created_at: :desc).first(7)
    ).excluding(@publication).uniq.first(6)
  end

  def base_search
    return [] unless Searchkick.client.ping

    @base_search ||= Publication.search(
      @publication.tags.pluck(:name).join(' '),
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } },
      operator: 'or'
    ).includes([{ cover_attachment: :blob }])
  end

  def set_tale
    @publication = @commentable = Rails.cache.fetch("publication_#{params[:id]}", expires_in: 1.hour) do
      Tale.find(params[:id])
    end
  end
end
