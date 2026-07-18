# frozen_string_literal: true

module Chapters
  # Validates chapter Action Text HTML size and inline pasted images.
  class ContentLimits
    MAX_BODY_BYTES = 2.megabytes
    MAX_INLINE_DATA_URI_ENCODED_BYTES = 400.kilobytes
    BASE64_MARKER = 'base64,'

    def self.errors_for(content)
      new(content).errors
    end

    def initialize(content)
      @html = extract_html(content)
    end

    def errors
      return [] if @html.blank?

      found = []
      found << [:body_too_large, { max_mb: MAX_BODY_BYTES / 1.megabyte }] if @html.bytesize > MAX_BODY_BYTES
      if inline_data_uri_too_large?
        found << [:inline_image_too_large, { max_kb: MAX_INLINE_DATA_URI_ENCODED_BYTES / 1.kilobyte }]
      end
      found
    end

    private

    def extract_html(content)
      case content
      when ActionText::RichText then content.body.to_html
      when ActionText::Content then content.to_html
      else content.to_s
      end
    end

    def inline_data_uri_too_large?
      pos = 0
      while (idx = @html.index(BASE64_MARKER, pos))
        encoded_start = idx + BASE64_MARKER.length
        encoded_end = encoded_end_for(encoded_start)
        return true if encoded_end && (encoded_end - encoded_start) > MAX_INLINE_DATA_URI_ENCODED_BYTES

        pos = encoded_start
      end
      false
    end

    def encoded_end_for(encoded_start)
      quote_end = @html.index('"', encoded_start)
      apostrophe_end = @html.index("'", encoded_start)
      [quote_end, apostrophe_end].compact.min
    end
  end
end
