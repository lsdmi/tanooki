# frozen_string_literal: true

module Fictions
  # Non-blocking cover quality check for persisted attachments.
  class CoverQuality
    Result = Data.define(:status, :reasons, :metadata) do
      def ok? = status == :ok
      def warn? = status == :warn
      def fail? = status == :fail
    end

    def self.call(fiction)
      new(fiction).call
    end

    def initialize(fiction)
      @attachment = fiction.cover
    end

    def call
      return fail_result(['Обкладинка відсутня.']) unless attachment&.attached?

      blob = attachment.blob
      dimensions = extract_dimensions(blob)
      return fail_result(['Не вдалося визначити розміри зображення.']) unless dimensions

      build_result(blob, dimensions)
    end

    private

    attr_reader :attachment

    def build_result(blob, dimensions)
      width, height = dimensions
      fail_reasons, warn_reasons = collect_reasons(blob, width, height)
      reasons = fail_reasons + warn_reasons
      status = status_for(fail_reasons, warn_reasons)
      metadata = { width: width, height: height, format: blob.content_type, byte_size: blob.byte_size }

      Result.new(status: status, reasons: reasons, metadata: metadata)
    end

    def collect_reasons(blob, width, height)
      fail_reasons = dimension_failures(width, height)
      warn_reasons = soft_issues(blob, width, height)

      [fail_reasons, warn_reasons]
    end

    def dimension_failures(width, height)
      failures = []
      min_width = CoverImageValidator::MIN_WIDTH
      min_height = CoverImageValidator::MIN_HEIGHT

      failures << "Ширина обкладинки має бути не менше #{min_width}px." if width < min_width
      failures << "Висота обкладинки має бути не менше #{min_height}px." if height < min_height
      failures
    end

    def soft_issues(blob, width, height)
      issues = []
      issues << 'Обкладинка не у форматі WebP або AVIF.' unless modern_format?(blob)
      if oversized?(blob)
        max_mb = CoverImageValidator::MAX_BYTE_SIZE / 1.megabyte
        issues << "Розмір файлу обкладинки не може перевищувати #{max_mb} МБ."
      end
      issues << 'Співвідношення сторін має бути близько 3:4.' unless aspect_ok?(width, height)
      issues
    end

    def status_for(fail_reasons, warn_reasons)
      return :fail if fail_reasons.any?
      return :warn if warn_reasons.any?

      :ok
    end

    def modern_format?(blob)
      blob.content_type.in?(CoverImageValidator::ALLOWED_CONTENT_TYPES)
    end

    def oversized?(blob)
      blob.byte_size > CoverImageValidator::MAX_BYTE_SIZE
    end

    def aspect_ok?(width, height)
      aspect = width.to_f / height
      (aspect - CoverImageValidator::IDEAL_ASPECT).abs <= CoverImageValidator::ASPECT_TOLERANCE
    end

    def extract_dimensions(blob)
      blob.open { |file| FastImage.size(file.path) }
    rescue StandardError
      nil
    end

    def fail_result(reasons)
      Result.new(status: :fail, reasons: Array(reasons), metadata: {})
    end
  end
end
