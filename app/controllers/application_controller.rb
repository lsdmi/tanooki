# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from StandardError, with: :handle_error if Rails.env.production?

  helper_method :latest_comments, :trending_tags, :recent_ranobe, :popular_blogs, :popular_videos,
                :adsense_allowed?

  def handle_error
    render :error, status: :internal_server_error
  end

  private

  def pokemon_appearance
    return if params[:page].present?

    @wild_pokemon = Pokemons::WildCatch.new(user: current_user, session:).call
  end

  def refresh_sweetalert
    turbo_stream.replace('sweet-alert', partial: 'shared/sweet_alert')
  end

  def latest_comments
    Rails.cache.fetch("latest_comments_for_#{current_user.id}", expires_in: 10.minutes) do
      CommentsFetcher.new(current_user).collect
    end
  end

  def trending_tags
    Tags::Trending.new.tags
  end

  def track_visit
    Analytics::ViewIncrement.new(
      @publication || @chapter || @fiction || @youtube_video || @bookshelf,
      session
    ).call
  end

  def verify_user_permissions
    redirect_to root_path unless current_user.admin?
  end

  def adsense_allowed?
    Rails.env.production? && !ads_disabled_for_current_page?
  end

  def videos
    Rails.cache.fetch('videos', expires_in: 1.hour) do
      videos = ActionText::RichText.where('body LIKE ?', '%youtube.com/embed/%')
                                   .order(created_at: :desc)
                                   .limit(3)
                                   .flat_map do |rich_text|
        doc = Nokogiri::HTML.parse(rich_text.body.to_s)
        doc.css('iframe[src*="youtube.com/embed/"]').map { |iframe| iframe['src'] }
      end

      videos[0..2]
    end
  end

  def load_advertisement
    @advertisement = cached_sample_advertisement
  end

  def recent_ranobe
    Rails.cache.fetch('recent_ranobe', expires_in: 1.hour) do
      ReadingProgress.includes(:fiction).order(:updated_at).last(3)
    end
  end

  def popular_blogs
    Rails.cache.fetch('popular_blogs', expires_in: 1.hour) do
      Publication.highlights.last_month.order(views: :desc).limit(2)
    end
  end

  def popular_videos
    Rails.cache.fetch('popular_videos', expires_in: 1.hour) do
      YoutubeVideo.last_month.order(views: :desc).limit(2)
    end
  end

  def cached_sample_advertisement
    bucket = Time.current.to_i / 10.minutes.to_i
    Rails.cache.fetch(['enabled_ad_sample', bucket], expires_in: 10.minutes) do
      Advertisement.includes(%i[cover_attachment poster_attachment]).enabled.sample
    end
  end

  def ads_disabled_for_current_page?
    false
  end
end
