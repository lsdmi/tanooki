# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @highlights = highlights
    @most_popular = most_popular
    @newest = newest
    @pagy, @publications = pagy_countless(remaining, items: 5)

    @advertisement = Advertisement.enabled.sample

    render 'scrollable_list' if params[:page]
  end

  private

  def highlights
    highlights = Publication.highlights.order(created_at: :desc).first(3)

    return highlights unless highlights.size < 3

    fallback_tales_count = 3 - highlights.size
    highlights += Tale.not_highlights.order(created_at: :desc).first(fallback_tales_count)
    highlights
  end

  def most_popular
    Publication.approved.last_month.excluding(@highlights).order(views: :desc).limit(5)
  end

  def newest
    Publication.approved.order(created_at: :desc).excluding(@highlights, @most_popular).limit(10)
  end

  def remaining
    Publication.approved.order(created_at: :desc).excluding(@highlights, @most_popular, @newest)
  end
end
