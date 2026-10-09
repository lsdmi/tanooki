# frozen_string_literal: true

module Api
  module Chapters
    # Markdown or HTML from the caller becomes the same HTML the composer stores.
    class Content
      MAX_BYTES = 1.megabyte

      def self.call(text, format)
        raw = text.to_s
        raise Error.new('content_too_large', :unprocessable_entity) if raw.bytesize > MAX_BYTES
        raise Error.new('base64_image', :unprocessable_entity) if raw.include?(::Chapters::ContentLimits::BASE64_MARKER)

        html = format.to_s == 'html' ? raw : ::Chapters::MarkdownToHtml.call(raw)
        ::Chapters::ApiContentSanitizer.call(html)
      end
    end
  end
end
