# frozen_string_literal: true

module Fictions
  # Converts JPEG/PNG cover uploads to WebP before validation and persistence.
  # Always stores a neutral filename so broken-image alt/URL never leak upload names.
  class CoverUploadNormalizer
    class Error < StandardError; end

    NEUTRAL_BASENAME = 'cover'

    def self.call(upload)
      new(upload).call
    end

    def initialize(upload)
      @upload = upload
    end

    def call
      return upload if upload.blank?

      if CoverImageValidator::ALLOWED_CONTENT_TYPES.include?(content_type)
        return with_neutral_filename(upload, extension_for_allowed)
      end
      return upload unless CoverImageValidator::CONVERTIBLE_CONTENT_TYPES.include?(content_type)

      unless Attachments::VariantProcessing.available?
        raise Error, 'Не вдалося конвертувати JPEG/PNG. Завантажте WebP або AVIF.'
      end

      build_webp_upload
    end

    private

    attr_reader :upload

    def build_webp_upload
      output = Tempfile.new([NEUTRAL_BASENAME, '.webp'])
      convert_to_webp(output.path)

      uploaded_file(output, filename: "#{NEUTRAL_BASENAME}.webp", type: 'image/webp')
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

    def with_neutral_filename(file, extension)
      name = "#{NEUTRAL_BASENAME}#{extension}"
      return file if File.basename(file.original_filename.to_s) == name

      tempfile = file.respond_to?(:tempfile) ? file.tempfile : File.open(upload_path)
      uploaded_file(tempfile, filename: name, type: content_type)
    end

    def uploaded_file(tempfile, filename:, type:)
      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: filename,
        type: type
      )
    end

    def extension_for_allowed
      content_type == 'image/avif' ? '.avif' : '.webp'
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
  end
end
