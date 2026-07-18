# frozen_string_literal: true

module Chapters
  # Thresholds for inline image compression (not save-time validation).
  module ContentLimits
    MAX_INLINE_DATA_URI_ENCODED_BYTES = 400.kilobytes
    BASE64_MARKER = 'base64,'
  end
end
