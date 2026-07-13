# frozen_string_literal: true

module Fictions
  # Converts JPEG/PNG cover uploads to WebP before validation and persistence.
  class CoverUploadNormalizer
    class Error < StandardError; end

    def self.call(upload)
      new(upload).call
    end

    def initialize(upload)
      @upload = upload
    end

    def call
      return upload if upload.blank?
      return upload if CoverImageValidator::ALLOWED_CONTENT_TYPES.include?(content_type)
      return upload unless CoverImageValidator::CONVERTIBLE_CONTENT_TYPES.include?(content_type)

      unless Attachments::VariantProcessing.available?
        raise Error, 'Не вдалося конвертувати JPEG/PNG. Завантажте WebP або AVIF.'
      end

      build_webp_upload
    end

    private

    attr_reader :upload

    def build_webp_upload
      output = Tempfile.new(['cover', '.webp'])
      convert_to_webp(output.path)

      uploaded_webp_file(output)
    rescue StandardError
      output&.close!
      raise Error, 'Не вдалося конвертувати JPEG/PNG. Завантажте WebP або AVIF.'
    end

    def convert_to_webp(destination)
      ImageProcessing::Vips
        .source(upload_path)
        .convert('webp')
        .saver(quality: 85)
        .call(destination: destination)
    end

    def uploaded_webp_file(output)
      ActionDispatch::Http::UploadedFile.new(
        tempfile: output,
        filename: webp_filename,
        type: 'image/webp'
      )
    end

    def upload_path
      if upload.respond_to?(:tempfile)
        upload.tempfile.path
      else
        upload.path
      end
    end

    def content_type
      upload.content_type.to_s.downcase
    end

    def webp_filename
      basename = File.basename(upload.original_filename.to_s, '.*')
      "#{basename.presence || 'cover'}.webp"
    end
  end
end
