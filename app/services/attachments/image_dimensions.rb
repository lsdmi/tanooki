# frozen_string_literal: true

module Attachments
  # Reads image width/height from Active Storage analyze metadata, with FastImage fallback.
  class ImageDimensions
    def self.from_blob(blob)
      new(blob).dimensions
    end

    def initialize(blob)
      @blob = blob
    end

    def dimensions
      from_metadata || from_fast_image
    end

    private

    attr_reader :blob

    def from_metadata
      metadata = blob.metadata
      width = metadata['width']
      height = metadata['height']
      return unless width.to_i.positive? && height.to_i.positive?

      [width.to_i, height.to_i]
    rescue StandardError
      nil
    end

    def from_fast_image
      blob.open { |file| FastImage.size(file.path) }
    rescue StandardError
      nil
    end
  end
end
