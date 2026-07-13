# frozen_string_literal: true

# Validates uploaded fiction covers: WebP/AVIF (or convertible JPEG/PNG), 3:4 aspect, min dimensions, and max file size.
class CoverImageValidator
  ALLOWED_CONTENT_TYPES = %w[image/webp image/avif].freeze
  CONVERTIBLE_CONTENT_TYPES = %w[image/jpeg image/jpg image/png].freeze
  ACCEPTED_UPLOAD_CONTENT_TYPES = (ALLOWED_CONTENT_TYPES + CONVERTIBLE_CONTENT_TYPES).freeze
  MIN_WIDTH = 600
  MIN_HEIGHT = 800
  IDEAL_ASPECT = 0.75
  ASPECT_TOLERANCE = 0.1
  MAX_BYTE_SIZE = 2.megabytes

  attr_reader :file, :errors

  def initialize(file)
    @file = file
    @errors = []
  end

  def valid?
    return true if file.blank?

    validate_format
    validate_byte_size
    dimensions = extract_dimensions

    if dimensions
      validate_width(dimensions[0])
      validate_height(dimensions[1])
      validate_aspect_ratio(dimensions)
    end

    errors.empty?
  end

  private

  def validate_format
    return if file.content_type.in?(ALLOWED_CONTENT_TYPES)

    errors << 'Обкладинка має бути WebP, AVIF, JPEG або PNG.'
  end

  def validate_byte_size
    return if byte_size <= MAX_BYTE_SIZE

    errors << "Розмір файлу обкладинки не може перевищувати #{MAX_BYTE_SIZE / 1.megabyte} МБ."
  end

  def extract_dimensions
    FastImage.size(file.tempfile.path).tap do |dims|
      errors << 'Не вдалося визначити розміри зображення.' unless dims
    end
  end

  def validate_width(width)
    errors << "Ширина обкладинки має бути не менше #{MIN_WIDTH}px." if width < MIN_WIDTH
  end

  def validate_height(height)
    errors << "Висота обкладинки має бути не менше #{MIN_HEIGHT}px." if height < MIN_HEIGHT
  end

  def validate_aspect_ratio(dimensions)
    width, height = dimensions
    aspect = width.to_f / height
    return if (aspect - IDEAL_ASPECT).abs <= ASPECT_TOLERANCE

    errors << 'Співвідношення сторін обкладинки має бути близько 3:4.'
  end

  def byte_size
    if file.respond_to?(:size)
      file.size
    else
      File.size(file.tempfile.path)
    end
  end
end
