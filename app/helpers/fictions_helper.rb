# frozen_string_literal: true

# Fiction view helpers for status styling and compact counters.
module FictionsHelper
  STATUS_COLORS = {
    announced: 'text-[#D4AF37]', # Metallic Gold
    dropped: 'text-[#8B0000]',   # Dark Red
    ongoing: 'text-[#4682B4]',   # Steel Blue
    finished: 'text-[#2E8B57]'   # Sea Green
  }.freeze

  def genre_badge_slug(genre_name)
    Genre.badge_asset_slug(genre_name)
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
