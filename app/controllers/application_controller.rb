# frozen_string_literal: true

# Base controller: shared helpers, error handling, and layout data for all pages.
class ApplicationController < ActionController::Base
  include Pagy::Backend
  include TurboFlashStream
  include TurboFlashStreamResponse

  # Handlers declared later win, so the catch-all must come first or every missing record becomes a 500.
  rescue_from StandardError, with: :handle_error
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # Layout helpers (trending_tags, recent_ranobe, etc.) are fragment-cached in navbar/footer;
  # avoid adding uncached per-request queries to ApplicationController without a similar cache.
  helper_method :latest_comments, :trending_tags, :recent_ranobe, :popular_blogs, :popular_videos,
                :adsense_allowed?

  helper Adsense::PlacementsHelper

  def handle_error(error)
    raise error unless Rails.env.production?

    log_handled_error(error)
    Rails.error.report(error, handled: true)
    render :error, status: :internal_server_error
  end

  def record_not_found
    render file: Rails.public_path.join('404.html'), layout: false, status: :not_found
  end

  private

  def log_handled_error(error)
    Rails.logger.error(
      "[handle_error] #{request.method} #{request.path} #{error.class}: #{error.message}\n" \
      "#{Rails.backtrace_cleaner.clean(error.backtrace.to_a).first(15).join("\n")}"
    )
  end

  def pokemon_appearance
    # Opt-in via before_action on browse/discovery only — never a global filter
    # (skipped on fictions#index/show, chapters#show, studio).
    return if params[:page].present?

    @wild_encounter = Pokemons::WildCatch.new(user: current_user, session:).call
  end

  def latest_comments
    # Lazy nav badge / studio inbox only — not on the main HTML path.
    Rails.cache.fetch("latest_comments_for_#{current_user.id}", expires_in: 10.minutes) do
      Comments::InboxCollector.new(current_user).call
    end
  end

  def search_tag_counts(labels, scope: :all)
    Search::TagCounts.call(labels, scope: scope)
  end

  def trending_tags
    Tags::Trending.new.tags
  end

  def track_visit(record)
    return if turbo_prefetch_request?
    return if record.nil?

    Analytics::ViewIncrement.new(record, session).call
  end

  # Turbo Drive/preload fetches send this header; treat them as cache fills, not visits.
  def turbo_prefetch_request?
    return false unless request

    request.headers['X-Sec-Purpose'] == 'prefetch'
  end

  # Production traffic arrives through Cloudflare, so remote_ip is a Cloudflare edge address shared by
  # unrelated visitors; Cloudflare puts the visitor's address in CF-Connecting-IP (and overwrites any sent).
  def client_ip
    request.headers['CF-Connecting-IP'].presence || request.remote_ip
  end

  def verify_user_permissions
    redirect_to root_path unless current_user.admin?
  end

  def adsense_allowed?
    Rails.env.production?
  end

  def recent_ranobe
    Rails.cache.fetch('recent_ranobe', expires_in: 1.hour) do
      ReadingProgress.includes(:fiction).order(:updated_at).last(3)
    end
  end

  def popular_blogs
    Rails.cache.fetch(Publications::PublicCache::POPULAR_BLOGS_KEY, expires_in: 1.hour) do
      Publication.published.highlights.weekly.order(views: :desc).limit(2)
    end
  end

  def popular_videos
    Rails.cache.fetch('popular_videos', expires_in: 1.hour) do
      YoutubeVideo.last_month.order(views: :desc).limit(2)
    end
  end
end
