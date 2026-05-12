# frozen_string_literal: true

module Publications
  # Tailwind height class for the publication cover header, from title character count.
  module CoverHeaderHelper
    def cover_header_height_class(character_count)
      case character_count
      when 75..Float::INFINITY
        'h-80'
      when 50..74
        'h-72'
      when 25..49
        'h-64'
      else
        'h-60'
      end
    end
  end
end
