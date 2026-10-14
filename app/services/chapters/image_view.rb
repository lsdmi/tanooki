# frozen_string_literal: true

module Chapters
  # One still frame small enough to send to a chat. An animation stays one frame; the GIF header carries the motion.
  class ImageView
    Preview = Data.define(:binary, :mime, :animated, :frames, :duration_ms)
    MAX_EDGE = 1024

    def self.call(blob)
      blob.open { |file| build(file.path, blob.content_type) }
    end

    def self.build(path, content_type)
      info = GifInfo.call(path)
      binary, mime = still(path, content_type)
      return if binary.blank?

      Preview.new(binary:, mime:, animated: info&.frames.to_i > 1, frames: info&.frames, duration_ms: info&.duration_ms)
    end

    def self.still(path, content_type)
      return original(path, content_type) unless Attachments::VariantProcessing.available?

      require 'vips'
      image = Vips::Image.new_from_file(path, n: 1, access: :sequential, fail_on: :error)
      thumb = image.thumbnail_image(MAX_EDGE, height: MAX_EDGE, size: :down)
      [thumb.webpsave_buffer(Q: 80, strip: true), 'image/webp']
    rescue StandardError
      original(path, content_type)
    end

    def self.original(path, content_type)
      return unless ImageProcessor::KEPT_TYPES.key?(content_type)
      return if File.size(path) > 1.megabyte

      [File.binread(path), content_type]
    end

    private_class_method :build, :still, :original
  end
end
