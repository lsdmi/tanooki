# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pagy::Backend

  helper_method :trending_tags

  before_action :pokemon_appearance, only: %i[index show]

  private

  def pokemon_appearance
    @wild_pokemon = PokemonService.new(guest: current_user.nil?, session:).call
  end

  def trending_tags
    TrendingTagsService.call
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
    @advertisement = Advertisement.includes([{ cover_attachment: :blob }]).enabled.sample
  end
end
