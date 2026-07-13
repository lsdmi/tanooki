# frozen_string_literal: true

module CoverUploadHelper
  VALID_COVER_PATH = Rails.root.join('test/fixtures/files/cover_valid.webp').freeze

  def valid_cover_upload(content_type: 'image/webp')
    Rack::Test::UploadedFile.new(VALID_COVER_PATH, content_type)
  end

  def valid_png_cover_upload
    path = Rails.root.join('tmp/test_cover_valid.png')
    FileUtils.mkdir_p(path.dirname)

    unless path.exist?
      ImageProcessing::Vips
        .source(VALID_COVER_PATH.to_s)
        .convert('png')
        .call(destination: path.to_s)
    end

    Rack::Test::UploadedFile.new(path, 'image/png')
  end
end
