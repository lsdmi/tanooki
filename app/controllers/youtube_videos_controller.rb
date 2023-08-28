# frozen_string_literal: true

class YoutubeVideosController < ApplicationController
  before_action :set_video, :track_visit, only: :show
  before_action :load_advertisement

  def index
    @highlights = highlights
    @popular = popular
    @latest = latest
    @pagy, @other = pagy_countless(other, items: 12)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @more_videos = more_videos
    @comments = @youtube_video.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def highlights
    base_query.order(published_at: :desc).first(4)
  end

  def popular
    base_query.excluding(@highlights).last_month.order(views: :desc).first(9)
  end

  def latest
    base_query.excluding(@highlights, @popular).order(published_at: :desc).first(7)
  end

  def other
    base_query.excluding(@highlights, @popular, @latest).order(published_at: :desc)
  end

  def base_query
    YoutubeVideo.includes(:youtube_channel, :rich_text_description)
  end

  def more_videos
    YoutubeVideo.includes(:youtube_channel)
                .where(youtube_channel_id: @youtube_video.youtube_channel_id)
                .excluding(@youtube_video).order(published_at: :desc).first(4)
  end

  def set_video
    @youtube_video = @commentable = Rails.cache.fetch("video_#{params[:id]}", expires_in: 1.hour) do
      YoutubeVideo.find(params[:id])
    end
  end
end
