# frozen_string_literal: true

class BannerImageValidator
  MIN_WIDTH = 1000
  IDEAL_ASPECT = 3.0
  ASPECT_MARGIN = 1.3

  attr_reader :file, :errors

  def initialize(file)
    @file = file
    @errors = []
  end

  def valid?
    return true unless file.present?

    validate_format
    dimensions = extract_dimensions

    if dimensions
      validate_width(dimensions[0])
      validate_aspect_ratio(dimensions)
    end

    errors.empty?
  end

  private

  def validate_format
    errors << 'Банер має бути у форматі WebP.' unless file.content_type == 'image/webp'
  end

  def extract_dimensions
    FastImage.size(file.tempfile.path).tap do |dims|
      errors << 'Не вдалося визначити розміри зображення.' unless dims
    end
  end

  def validate_width(width)
    errors << "Ширина банера має бути не менше #{MIN_WIDTH}px." if width < MIN_WIDTH
  end

  def validate_aspect_ratio(dimensions)
    width, height = dimensions
    aspect = width.to_f / height
    return if (aspect - IDEAL_ASPECT).abs <= ASPECT_MARGIN

    errors << "Співвідношення сторін має бути близько #{IDEAL_ASPECT}:1."
  end
end
