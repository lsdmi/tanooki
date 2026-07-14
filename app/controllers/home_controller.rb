# frozen_string_literal: true

# Landing page with featured fictions, tales, and advertisements.
class HomeController < ApplicationController
  before_action :pokemon_appearance, only: [:index]

  def index
    @hero_banner = Root::HeroBanner.current(preview_key: params[:banner])
    @top_fictions = top_fictions
    assign_recently_updated
    @videos = videos
    @video_tag_counts = search_tag_counts(
      Search::TagCounts.labels_from_youtube_videos(@videos, limit: Search::TagCounts::HOME_YOUTUBE_TAG_LIMIT)
    )
    @top_tales = top_tales
    @tales = tales
    @pokemon_ad = Advertisement.find_by(slug: 'pokemon')
  end

  private

  def tales
    Publication.includes(:rich_text_description).order(created_at: :desc).excluding(@top_tales).limit(10)
  end

  def top_fictions
    Fictions::IndexVariablesManager.hot_updates.includes(:genres, :fiction_ratings)
  end

  def assign_recently_updated
    @recently_updated_fictions = Fictions::IndexVariablesManager.latest_updates_for_homepage
    return if @recently_updated_fictions.blank?

    @recently_updated_chapters = Fictions::LatestReleasedChapters.for_fiction_ids(
      @recently_updated_fictions.map(&:id)
    )
  end

  def top_tales
    Rails.cache.fetch('top_tales', expires_in: 12.hours) do
      Publication.highlights.includes({ cover_attachment: :blob },
                                      :rich_text_description).last_month.order(views: :desc).limit(2)
    end
  end

  def videos
    Rails.cache.fetch('top_videos', expires_in: 12.hours) do
      YoutubeVideo.includes(:youtube_channel).last_month.order(views: :desc).limit(2)
    end
  end
end
