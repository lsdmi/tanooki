# frozen_string_literal: true

module Chapters
  # Higher-quality shrink settings for legacy chapter repair (EPUB export stays at 600px / Q80).
  module InlineImageOptimizer
    MAX_EDGE = 1200
    JPEG_QUALITY = 88

    module_function

    def optimize_data_uri_in_html(html, value_start, value_end)
      Books::EpubDataUriImageOptimizer.optimize_data_uri_in_html(
        html,
        value_start,
        value_end,
        max_edge: MAX_EDGE,
        jpeg_quality: JPEG_QUALITY
      )
    end
  end
end
