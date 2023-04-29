# frozen_string_literal: true

class TalesController < ApplicationController
  before_action :set_tale, :track_visit

  def show
    @more_tales = more_tails
    @comments = @publication.comments.parents.order(created_at: :desc)
    @comment = Comment.new
    @advertisement = Advertisement.includes([{ cover_attachment: :blob }, :rich_text_description]).enabled.sample
  end

  private

  def more_tails
    more = Publication.search(
      @publication.tags.pluck(:name).join(' '),
      fields: ['tags^10', 'title^5', 'description'],
      boost_by_recency: { created_at: { scale: '30d', decay: 0.9 } },
      operator: 'or'
    ).includes([{ cover_attachment: :blob }, :rich_text_description])

    return more.excluding(@publication).first(6) if more.size > 6

    (
      more.to_a + Publication.all.order(created_at: :desc).first(6)
    ).excluding(@publication).uniq.first(6)
  end

  def set_tale
    @publication = Tale.find(params[:id])
    response.headers['Cache-Control'] = 'public, max-age=31536000'
  end
end
