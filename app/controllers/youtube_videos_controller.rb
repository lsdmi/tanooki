# frozen_string_literal: true

class YoutubeVideosController < ApplicationController
  before_action :set_video, :track_visit, only: :show
  before_action :load_advertisement

  def index
    @highlights = YoutubeVideo.order(published_at: :desc).first(4)
    @latest = YoutubeVideo.excluding(@highlights).order(published_at: :desc).first(6)
  end

  def show
    @more_videos = more_videos
    @comments = @youtube_video.comments.parents.order(created_at: :desc)
    @comment = Comment.new
  end

  private

  def more_videos
    YoutubeVideo.includes(:youtube_channel)
                .where(youtube_channel_id: @youtube_video.youtube_channel_id)
                .excluding(@youtube_video).first(4)
  end

  def set_video
    @youtube_video = @commentable = Rails.cache.fetch("video_#{params[:id]}", expires_in: 1.hour) do
      YoutubeVideo.find(params[:id])
    end
  end
end
