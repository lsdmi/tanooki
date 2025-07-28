# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from StandardError, with: :handle_error if Rails.env.production?

  helper_method :latest_comments, :trending_tags, :recent_ranobe, :popular_blogs, :popular_videos

  before_action :pokemon_appearance, only: %i[index show]
  before_action :log_authentication_state
  after_action :log_memory_usage
  after_action :log_session_exit_state

  def handle_error
    render :error, status: :internal_server_error
  end

  private

  def log_authentication_state
    session_id = session.id
    user_id = current_user&.id
    user_email = current_user&.email
    authenticated = user_signed_in?
    debug_user_id = session[:debug_user_id]

    # Add user_id to session for better tracking
    if authenticated && user_id && debug_user_id != user_id
      session[:debug_user_id] = user_id
      Rails.logger.info "SESSION_ENTRY_CHECK: Added debug_user_id to session: #{user_id} - Session ID: #{session_id}"
    end

    Rails.logger.info "SESSION_ENTRY_CHECK: Authentication check - Controller: #{controller_name}, Action: #{action_name}, Session ID: #{session_id}, User ID: #{user_id}, User Email: #{user_email}, Authenticated: #{authenticated}, Debug User ID: #{debug_user_id}, Time: #{Time.current}"

    # Log detailed user information if authenticated
    if authenticated && current_user
      Rails.logger.info "SESSION_ENTRY_CHECK: User details - ID: #{current_user.id}, Email: #{current_user.email}, Class: #{current_user.class}"
      Rails.logger.info "SESSION_ENTRY_CHECK: User object inspect: #{current_user.inspect}"
    end

    # Log session data for debugging (Warden uses string keys like "warden.user.user.key")
    warden_keys = session.keys.select { |k| k.to_s.start_with?('warden.') }
    if warden_keys.any?
      Rails.logger.info "SESSION_ENTRY_CHECK: ✅ Warden authentication keys present: #{warden_keys.join(', ')} - Session ID: #{session_id}, Time: #{Time.current}"
      warden_keys.each do |key|
        warden_value = session[key]
        Rails.logger.info "SESSION_ENTRY_CHECK: #{key}: #{warden_value.inspect}"

        # If this is a user object, show more details
        if warden_value.respond_to?(:id) && warden_value.respond_to?(:email)
          Rails.logger.info "SESSION_ENTRY_CHECK: Warden user object - ID: #{warden_value.id}, Email: #{warden_value.email}, Class: #{warden_value.class}"
        end
      end
    else
      Rails.logger.warn "SESSION_ENTRY_CHECK: ❌ No Warden authentication keys found - Session ID: #{session_id}, Time: #{Time.current}"
    end

    # Simple cookie logging
    auth_cookie = cookies['_tanooki_session']
    remember_cookie = cookies['remember_user_token']

    Rails.logger.info "SESSION_ENTRY_CHECK: Auth cookie present: #{auth_cookie.present?}, Remember cookie present: #{remember_cookie.present?}"

    return unless auth_cookie.present?

    Rails.logger.info "SESSION_ENTRY_CHECK: Auth cookie length: #{auth_cookie.length}"
  end

  def log_session_exit_state
    session_id = session.id
    user_id = current_user&.id
    user_email = current_user&.email
    authenticated = user_signed_in?
    debug_user_id = session[:debug_user_id]

    Rails.logger.info "SESSION_EXIT_CHECK: Session exit state - Controller: #{controller_name}, Action: #{action_name}, Session ID: #{session_id}, User ID: #{user_id}, User Email: #{user_email}, Authenticated: #{authenticated}, Debug User ID: #{debug_user_id}, Time: #{Time.current}"

    # Log detailed user information if authenticated
    if authenticated && current_user
      Rails.logger.info "SESSION_EXIT_CHECK: User details - ID: #{current_user.id}, Email: #{current_user.email}, Class: #{current_user.class}"
      Rails.logger.info "SESSION_EXIT_CHECK: User object inspect: #{current_user.inspect}"
    end

    # Log session data for debugging (Warden uses string keys like "warden.user.user.key")
    warden_keys = session.keys.select { |k| k.to_s.start_with?('warden.') }
    if warden_keys.any?
      Rails.logger.info "SESSION_EXIT_CHECK: ✅ Warden authentication keys present: #{warden_keys.join(', ')} - Session ID: #{session_id}, Time: #{Time.current}"
      warden_keys.each do |key|
        warden_value = session[key]
        Rails.logger.info "SESSION_EXIT_CHECK: #{key}: #{warden_value.inspect}"

        # If this is a user object, show more details
        if warden_value.respond_to?(:id) && warden_value.respond_to?(:email)
          Rails.logger.info "SESSION_EXIT_CHECK: Warden user object - ID: #{warden_value.id}, Email: #{warden_value.email}, Class: #{warden_value.class}"
        end
      end
    else
      Rails.logger.warn "SESSION_EXIT_CHECK: ❌ No Warden authentication keys found - Session ID: #{session_id}, Time: #{Time.current}"
    end

    # Check if session is being returned properly
    auth_cookie = cookies['_tanooki_session']
    remember_cookie = cookies['remember_user_token']

    Rails.logger.info "SESSION_EXIT_CHECK: Auth cookie present: #{auth_cookie.present?}, Remember cookie present: #{remember_cookie.present?}"

    if auth_cookie.present?
      Rails.logger.info "SESSION_EXIT_CHECK: Auth cookie length: #{auth_cookie.length}"

      # Check for suspicious short cookies that might indicate corruption
      if auth_cookie.length <= 50
        Rails.logger.warn "SESSION_EXIT_CHECK: ⚠️ SUSPICIOUS SHORT COOKIE - Length: #{auth_cookie.length} (normal cookies are 900+ chars)"
        Rails.logger.warn "SESSION_EXIT_CHECK: Full cookie value: #{auth_cookie}"
      end
    end

    # Log all session keys for debugging
    Rails.logger.info "SESSION_EXIT_CHECK: All session keys: #{session.keys.join(', ')}"

    # Check if session is empty but should have data
    if session.keys.empty? && authenticated
      Rails.logger.error "SESSION_EXIT_CHECK: 🚨 CRITICAL - User authenticated but session is empty! Session ID: #{session_id}"
    elsif session.keys.empty? && auth_cookie.present?
      Rails.logger.error "SESSION_EXIT_CHECK: 🚨 CRITICAL - Cookie present but session is empty! Session ID: #{session_id}"
    end

    # Check for user_id mismatch between current_user and debug_user_id
    if debug_user_id && user_id && debug_user_id != user_id
      Rails.logger.warn "SESSION_EXIT_CHECK: ⚠️ USER ID MISMATCH - Debug User ID: #{debug_user_id}, Current User ID: #{user_id}, Session ID: #{session_id}"
    end

    # NEW CHECK: Detect when there's user_id but no Warden keys (session corruption)
    if (user_id || debug_user_id) && warden_keys.empty?
      Rails.logger.error "SESSION_EXIT_CHECK: 🚨 SESSION CORRUPTION DETECTED - User ID present (#{user_id || debug_user_id}) but NO Warden keys! Session ID: #{session_id}"
      Rails.logger.error 'SESSION_EXIT_CHECK: This indicates the session was corrupted or Warden keys were lost during request processing'
      Rails.logger.error "SESSION_EXIT_CHECK: Session keys present: #{session.keys.join(', ')}"
      Rails.logger.error "SESSION_EXIT_CHECK: Auth cookie present: #{auth_cookie.present?}, Cookie length: #{auth_cookie&.length}"

      # Additional analysis for corrupted sessions
      if auth_cookie.present?
        Rails.logger.error 'SESSION_EXIT_CHECK: 🔍 CORRUPTED SESSION ANALYSIS:'
        Rails.logger.error 'SESSION_EXIT_CHECK: - User should be authenticated but Warden keys are missing'
        Rails.logger.error 'SESSION_EXIT_CHECK: - Possible causes:'
        Rails.logger.error 'SESSION_EXIT_CHECK:   * Warden keys were cleared during request processing'
        Rails.logger.error 'SESSION_EXIT_CHECK:   * Session store corruption'
        Rails.logger.error 'SESSION_EXIT_CHECK:   * Middleware interference'
        Rails.logger.error 'SESSION_EXIT_CHECK:   * Cookie corruption during transmission'
        Rails.logger.error 'SESSION_EXIT_CHECK:   * Session serialization/deserialization error'
      end
    end

    # Log session changes if we have a request ID for correlation
    return unless request.request_id

    Rails.logger.info "SESSION_EXIT_CHECK: Request ID: #{request.request_id}"
  end

  def log_memory_usage
    memory_usage = GetProcessMem.new.mb
    return unless memory_usage > 500

    Rails.logger.warn "High memory usage detected: #{memory_usage.round(2)}MB in #{controller_name}##{action_name}"
  end

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
end
