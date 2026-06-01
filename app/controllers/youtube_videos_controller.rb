# frozen_string_literal: true

# YouTube video index and watch pages with curated highlights and related videos.
class YoutubeVideosController < ApplicationController
  before_action :load_advertisement
  before_action :set_video, :track_visit, only: :show
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @highlight = highlight
    @popular = popular
    @latest = latest
    @pagy, @other_youtube_videos = pagy(other, limit: 4)
    @video_tag_counts = search_tag_counts(index_video_search_tags)

    return unless turbo_frame_request?

    render partial: 'video_list', locals: {
      other_youtube_videos: @other_youtube_videos,
      pagy: @pagy
    }
  end

  def show
    @more_videos = more_videos
    @video_tags = video_tags_for_sidebar
    @video_tag_counts = Search::TagCounts.call(@video_tags, scope: :all)
  end

  private

  def highlight
    YoutubeVideo.order(published_at: :desc).first
  end

  def popular
    YoutubeVideo.excluding(@highlight).last_month.order(views: :desc).first(4)
  end

  def latest
    YoutubeVideo.includes(:youtube_channel).excluding(@highlight, @popular).order(published_at: :desc).first(3)
  end

  def other
    YoutubeVideo.excluding(@highlight, @popular, @latest).order(published_at: :desc)
  end

  def more_videos
    YoutubeVideo
      .where(youtube_channel_id: @youtube_video.youtube_channel_id)
      .excluding(@youtube_video).order(published_at: :desc).first(2)
  end

  def set_video
    @youtube_video = Rails.cache.fetch("video_#{params[:id]}", expires_in: 1.hour) do
      YoutubeVideo.friendly.find(params[:id])
    end
  end

  def video_tags_for_sidebar
    return [] unless @youtube_video.tags?

    @youtube_video.tags.split(', ').sample(9)
  end

  def index_video_search_tags
    latest_labels = Search::TagCounts.labels_from_youtube_videos(@latest, limit: 3)
    highlight_labels = Search::TagCounts.labels_from_youtube_video(@highlight, limit: 5)
    (latest_labels + highlight_labels).uniq
  end
end
