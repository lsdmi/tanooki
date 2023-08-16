# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_advertisement, only: :index

  def index
    @highlights = highlights
    @most_popular = most_popular
    @newest = newest
    @pagy, @publications = pagy_countless(remaining, items: 5)
    @videos = videos
    @hero_fictions_ad = Advertisement.find_by(slug: 'home-index-fictions-hero-ad')

    render 'scrollable_list' if params[:page]
  end

  private

  def highlights
    Publication.highlights.includes([{ cover_attachment: :blob }, :rich_text_description])
               .order(created_at: :desc).first(3)
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
