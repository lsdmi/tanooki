# frozen_string_literal: true

module Fictions
  # Compact view counts and genre badge asset slugs for fiction UI.
  module FormattingHelper
    STATUS_COLORS = {
      announced: 'text-[#D4AF37]', # Metallic Gold
      dropped: 'text-[#8B0000]',   # Dark Red
      ongoing: 'text-[#4682B4]',   # Steel Blue
      finished: 'text-[#2E8B57]'   # Sea Green
    }.freeze

    def genre_badge_slug(genre_name)
      Genre.badge_asset_slug(genre_name)
    end

    def badge_asset_available?(badge_slug)
      return false if badge_slug.blank?

      Rails.application.assets.load_path.find("badges/#{badge_slug}.webp").present?
    end

    def format_view_count(count)
      if count >= 1000
        formatted = (count / 1000.0).round(1)
        "#{formatted}т"
      else
        count.to_s
      end
    end
  end
end
