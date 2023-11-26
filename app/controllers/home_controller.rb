# frozen_string_literal: true

class HomeController < ApplicationController
  before_action :load_advertisement

  def index
    @top_fictions = top_fictions
    @videos = videos
    @top_tales = top_tales
    @tales = tales
  end

  private

  def tales
    Publication.includes(:rich_text_description).order(created_at: :desc).excluding(@top_tales).limit(10)
  end

  def top_fictions
    Rails.cache.fetch('top_fictions', expires_in: 12.hours) do
      Fiction.joins(:readings).includes([{ cover_attachment: :blob }, :scanlators]).group(:id).where(readings: { created_at: 1.month.ago..Time.now }).order('COUNT(readings.fiction_id) DESC').limit(10)
    end
  end

  def top_tales
    Rails.cache.fetch('top_tales', expires_in: 12.hours) do
      Publication.highlights.includes({ cover_attachment: :blob }, :rich_text_description).last_month.order(views: :desc).limit(2)
    end
  end

  def videos
    Rails.cache.fetch('top_videos', expires_in: 12.hours) do
      YoutubeVideo.includes(:rich_text_description, :youtube_channel).last_week.order(views: :desc).limit(2)
    end
  end
end
