# frozen_string_literal: true

module CoverUploadHelper
  VALID_COVER_PATH = Rails.root.join('test/fixtures/files/cover_valid.webp').freeze

  def valid_cover_upload(content_type: 'image/webp')
    Rack::Test::UploadedFile.new(VALID_COVER_PATH, content_type)
  end
end
