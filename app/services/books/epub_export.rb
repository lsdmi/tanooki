# frozen_string_literal: true

module Books
  # Builds a temporary EPUB file from chapter +ActionText::RichText+ ids (optional volume title for naming).
  class EpubExport
    attr_reader :file_path, :filename

    def initialize(rich_text_ids, volume_title = nil, export_request_id: nil)
      @rich_texts = ActionText::RichText.where(id: Array(rich_text_ids))
      @volume_title = volume_title
      @chapters = @rich_texts.map(&:record)
      suffix = export_request_id || SecureRandom.hex(8)
      @file_path = Rails.root.join('tmp', "epub_export_#{suffix}.epub").to_s
    end

    def generate
      book = build_book
      book.generate_epub(@file_path)
      set_filename
      self
    end

    private

    def build_book
      Books::EpubBuilder.new(@chapters, @volume_title).build
    end

    def set_filename
      @filename = if @chapters.size == 1
                    "#{@chapters.first.fiction_title}. #{Books::EpubChapterHtml.title(@chapters.first)}.epub"
                  else
                    "#{@chapters.first.fiction_title} #{@volume_title}.epub"
                  end
    end
  end
end
