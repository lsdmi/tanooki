# frozen_string_literal: true

class YoutubeVideosController < ApplicationController
  before_action :load_advertisement
  before_action :set_video, :track_visit, only: :show
  before_action :pokemon_appearance, only: %i[index show]

  def index
    @highlight = highlight
    @popular = popular
    @latest = latest
    @pagy, @other_youtube_videos = pagy(other, limit: 4)

    return unless turbo_frame_request?

    render partial: 'video_list', locals: {
      other_youtube_videos: @other_youtube_videos,
      pagy: @pagy
    }
  end

  def show
    @more_videos = more_videos
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
      YoutubeVideo.find(params[:id])
    end
  end
end
