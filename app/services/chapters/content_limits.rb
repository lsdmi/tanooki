# frozen_string_literal: true

module Chapters
  # Thresholds for inline image compression (not save-time validation).
  module ContentLimits
    MAX_INLINE_DATA_URI_ENCODED_BYTES = 400.kilobytes
    BASE64_MARKER = 'base64,'

    # Bodies above this are left to an operator-run pass; rewriting them in a worker
    # peaks past the job container's memory budget and takes the whole container down.
    MAX_AUTOMATED_COMPRESS_BODY_BYTES = 4.megabytes
  end
end
