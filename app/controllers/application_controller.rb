# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  rescue_from StandardError, with: :handle_error if Rails.env.production?

  helper_method :latest_comments, :trending_tags, :trending_tags_footer

  before_action :pokemon_appearance, only: %i[index show]

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
    Rails.cache.fetch("latest_comments_for_#{current_user.id}", expires_in: 1.hour) do
      CommentsFetcher.new(current_user).collect
    end
  end

  def trending_tags
    TrendingTagsService.new.navbar
  end

  def trending_tags_footer
    TrendingTagsService.new.footer
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
end
