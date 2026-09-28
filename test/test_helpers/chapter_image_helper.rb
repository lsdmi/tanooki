# frozen_string_literal: true

module ChapterImageHelper
  def store_chapter_image(binary = File.binread(CoverUploadHelper::VALID_COVER_PATH))
    image = Chapters::ImageProcessor::Result.new(
      binary:, content_type: 'image/webp', extension: 'webp', width: nil, height: nil
    )
    Chapters::Images.store!(image)
  end
end
