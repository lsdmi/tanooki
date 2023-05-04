# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_advertisement, only: :index

  def index
    @highlights = highlights
    @most_popular = most_popular
    @newest = newest
    @pagy, @publications = pagy_countless(remaining, items: 5)
    @videos = videos

    render 'scrollable_list' if params[:page]
  end

  private

  def highlights
    highlights = Publication.highlights.includes([{ cover_attachment: :blob }, :rich_text_description])
                            .order(created_at: :desc).first(3)

    return highlights unless highlights.size < 3

    fallback_tales_count = 3 - highlights.size
    highlights += Tale.not_highlights.includes([{ cover_attachment: :blob }, :rich_text_description])
                      .order(created_at: :desc).first(fallback_tales_count)
    highlights
  end

  def most_popular
    Publication.includes({ cover_attachment: :blob })
               .last_month.excluding(@highlights).order(views: :desc).limit(5)
  end

  def newest
    Publication.includes([{ cover_attachment: :blob }, :rich_text_description])
               .order(created_at: :desc).excluding(@highlights, @most_popular).limit(10)
  end

  def remaining
    Publication.includes([{ cover_attachment: :blob }, :rich_text_description])
               .order(created_at: :desc).excluding(@highlights, @most_popular, @newest)
  end
end
