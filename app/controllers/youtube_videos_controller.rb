# frozen_string_literal: true

# YouTube video index and watch pages with curated highlights and related videos.
class YoutubeVideosController < ApplicationController
  before_action :set_video, :track_visit, only: :show
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @highlight = highlight
    @popular = popular
    @latest = latest
    @pagy, @other_youtube_videos = pagy(other, limit: Root::VideosHelper::SUPPORTING_VIDEO_COUNT)
    @video_tag_counts = search_tag_counts(index_video_search_tags)

    return if turbo_frame_request_id.blank?

    partial, locals = video_list_turbo_response
    return unless partial

    render partial:, locals:
  end

  def show
    @more_videos = more_videos
    @video_tags = video_tags_for_sidebar
    @video_tag_counts = Search::TagCounts.call(@video_tags, scope: :all)
  end

  private

  def highlight
    YoutubeVideo.one_per_video.order(published_at: :desc).first
  end

  def popular
    YoutubeVideo.one_per_video.excluding_video(@highlight).last_month.order(views: :desc).first(4)
  end

  def latest
    YoutubeVideo.one_per_video.includes(:youtube_channel)
                .excluding_video(@highlight, @popular).order(published_at: :desc).first(3)
  end

  def other
    YoutubeVideo.one_per_video.excluding_video(@highlight, @popular, @latest).order(published_at: :desc)
  end

  def more_videos
    YoutubeVideo.one_per_video
                .where(youtube_channel_id: @youtube_video.youtube_channel_id)
                .excluding_video(@youtube_video).order(published_at: :desc).first(3)
  end

  def set_video
    @youtube_video = Rails.cache.fetch("video_#{params[:id]}", expires_in: 1.hour) do
      YoutubeVideo.friendly.find(params.expect(:id))
    end
  end

  def video_tags_for_sidebar
    return [] unless @youtube_video.tags?

    @youtube_video.tags.split(', ')
  end

  def video_list_turbo_response
    locals = {
      other_youtube_videos: @other_youtube_videos,
      pagy: @pagy,
      video_tag_counts: @video_tag_counts
    }

    case turbo_frame_request_id
    when 'video-list' then ['video_list', locals]
    when 'video-list-mobile' then ['video_list_mobile', locals]
    end
  end

  def index_video_search_tags
    [
      tag_labels_for_videos(@latest, limit: Search::TagCounts::INDEX_LATEST_YOUTUBE_TAG_LIMIT),
      tag_labels_for_video(@highlight, limit: Search::TagCounts::INDEX_HIGHLIGHT_YOUTUBE_TAG_LIMIT),
      tag_labels_for_videos(@other_youtube_videos, limit: Search::TagCounts::HOME_YOUTUBE_TAG_LIMIT)
    ].flatten.uniq
  end

  def tag_labels_for_videos(videos, limit:)
    Search::TagCounts.labels_from_youtube_videos(videos, limit:)
  end

  def tag_labels_for_video(video, limit:)
    Search::TagCounts.labels_from_youtube_video(video, limit:)
  end
end
