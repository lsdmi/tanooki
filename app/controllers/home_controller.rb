# frozen_string_literal: true

# Landing page with featured fictions, tales, videos, and promotional content.
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
    @top_tale = top_tale
    @tales = tales
  end

  private

  def tales
    scope = Publication
            .includes(:rich_text_description, cover_attachment: :blob)
            .order(created_at: :desc)
    scope = scope.where.not(id: @top_tale.id) if @top_tale
    scope.limit(Root::TalesHelper::EDITORIAL_TALE_LIMIT)
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

  def top_tale
    publication_id = Rails.cache.fetch('top_tale/v1', expires_in: 12.hours) do
      Publication.weekly.order(views: :desc).limit(1).pick(:id)
    end
    return Publication.last if publication_id.blank?

    Publication.includes({ cover_attachment: :blob }, :rich_text_description).find_by(id: publication_id)
  end

  def videos
    cached_ids = Rails.cache.fetch('home_videos/v1', expires_in: 12.hours) do
      YoutubeVideo.last_month.order(views: :desc).limit(Root::VideosHelper::HOME_VIDEO_LIMIT).pluck(:id)
    end
    return YoutubeVideo.order(published_at: :desc).first(4) if cached_ids.blank?

    YoutubeVideo.where(id: cached_ids).order(views: :desc)
  end
end
