# frozen_string_literal: true

module Chapters
  # Prepares one chapter image for storage, from editor uploads and from inline base64.
  # Small images keep their original bytes (so animated GIFs survive); larger ones become
  # WebP, which keeps transparency. Returns nil for files that are not a readable image.
  module ImageProcessor
    Result = Data.define(:binary, :content_type, :extension, :width, :height)

    KEEP_MAX_BYTES = 300.kilobytes
    MAX_EDGE = 1600
    WEBP_QUALITY = 82
    KEPT_TYPES = { 'image/jpeg' => 'jpg', 'image/png' => 'png', 'image/webp' => 'webp', 'image/gif' => 'gif' }.freeze
    CONVERTED_TYPES = %w[image/bmp image/x-bmp image/x-ms-bmp image/tiff].freeze

    module_function

    def call(path)
      content_type = detect(path)
      return unless KEPT_TYPES.key?(content_type) || CONVERTED_TYPES.include?(content_type)
      return keep_without_vips(path, content_type) unless Attachments::VariantProcessing.available?

      process(path, content_type)
    rescue StandardError => e
      Rails.logger.warn("[ChapterImages] unreadable image: #{e.class}: #{e.message}")
      nil
    end

    def detect(path)
      File.open(path, 'rb') { |file| Marcel::MimeType.for(file) }
    end

    def process(path, content_type)
      require 'vips'

      image = Vips::Image.new_from_file(path, access: :sequential, fail_on: :error)
      return webp(path) unless keep?(path, content_type, image)

      image.avg
      keep(path, content_type, image.width, image.height)
    end

    def keep?(path, content_type, image)
      return false if CONVERTED_TYPES.include?(content_type)
      return true if animated?(image)

      File.size(path) <= KEEP_MAX_BYTES && [image.width, image.height].max <= MAX_EDGE
    end

    def animated?(image)
      image.get_typeof('n-pages').positive? && image.get('n-pages') > 1
    end

    def keep(path, content_type, width, height)
      Result.new(binary: File.binread(path), content_type:, extension: KEPT_TYPES.fetch(content_type), width:, height:)
    end

    def keep_without_vips(path, content_type)
      return unless KEPT_TYPES.key?(content_type)

      keep(path, content_type, nil, nil)
    end

    def webp(path)
      Vips.cache_set_max(0)
      image = Vips::Image.thumbnail(path, MAX_EDGE, height: MAX_EDGE, size: :down, fail_on: :error)
      binary = image.webpsave_buffer(Q: WEBP_QUALITY, strip: true)
      Result.new(binary:, content_type: 'image/webp', extension: 'webp', width: image.width, height: image.height)
    end
  end
end
