# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from StandardError, with: :handle_error if Rails.env.production?

  helper_method :latest_comments, :trending_tags, :recent_ranobe, :popular_blogs, :popular_videos

  before_action :pokemon_appearance, only: %i[index show]
  before_action :log_session_debug if Rails.env.production?

  def handle_error
    render :error, status: :internal_server_error
  end

  private

  def pokemon_appearance
    return if params[:page].present?

    @wild_pokemon = PokemonService.new(user: current_user, session:).call
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
    TrendingTagsService.new.tags
  end

  def track_visit
    TrackingService.new(
      @publication || @chapter || @fiction || @youtube_video,
      session
    ).call
  end

  def verify_user_permissions
    redirect_to root_path unless current_user.admin?
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
    @advertisement = Advertisement.includes(%i[cover_attachment poster_attachment]).enabled.sample
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

  def log_session_debug
    session_size = session.to_hash.to_json.bytesize
    csrf_token = session[:_csrf_token]
    user_id = session['warden.user.user.key']&.first&.first

    # Check actual cookie size
    session_cookie = request.cookies['_tanooki_session']
    cookie_size = session_cookie&.bytesize || 0

    Rails.logger.info "[SESSION_DEBUG] Request: #{request.path} | Session size: #{session_size} bytes | Cookie size: #{cookie_size} bytes | CSRF token present: #{csrf_token.present?} | User ID: #{user_id} | IP: #{request.remote_ip}"

    if session_size > 4000
      Rails.logger.warn "[SESSION_DEBUG] WARNING: Session cookie is large (#{session_size} bytes) - may cause issues"
    end

    return unless cookie_size > 4000

    Rails.logger.warn "[SESSION_DEBUG] WARNING: Actual cookie size is large (#{cookie_size} bytes) - may cause issues"
  end
end
