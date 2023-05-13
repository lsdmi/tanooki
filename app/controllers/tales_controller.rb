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
    more = Publication.search(
      @publication.tags.pluck(:name).join(' '),
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '7d', decay: 0.9 } },
      operator: 'or'
    ).includes([{ cover_attachment: :blob }, :rich_text_description])

    return more.excluding(@publication).first(6) if more.size > 6

    (
      more.to_a + Publication.all.order(created_at: :desc).first(6)
    ).excluding(@publication).uniq.first(6)
  end

  def set_tale
    @publication = @commentable = Rails.cache.fetch("publication_#{params[:id]}", expires_in: 1.hour) do
      Tale.find(params[:id])
    end
  end
end
