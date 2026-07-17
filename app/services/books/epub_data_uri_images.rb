# frozen_string_literal: true

module Books
  # Replaces inline data-URI images with EPUB manifest assets and optional downscaling.
  class EpubDataUriImages
    def self.extract!(html, book:, chapter_key:, export_request_id: nil)
      new(html, book, chapter_key, export_request_id).extract!
    end

    def initialize(html, book, chapter_key, export_request_id)
      @html = html
      @book = book
      @chapter_key = chapter_key
      @export_request_id = export_request_id
    end

    def extract!
      EpubDataUriImageScanner.new(@html, book: @book, chapter_key: @chapter_key,
                                         export_request_id: @export_request_id).scan
    end
  end
end
