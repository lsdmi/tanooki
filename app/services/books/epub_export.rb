# frozen_string_literal: true

module Books
  # Builds a temporary EPUB file from chapter +ActionText::RichText+ ids (optional volume title for naming).
  class EpubExport
    attr_reader :file_path, :filename

    def initialize(rich_text_ids, volume_title = nil, export_request_id: nil)
      @rich_text_ids = Array(rich_text_ids).map(&:to_i)
      @volume_title = volume_title
      @export_request_id = export_request_id
      suffix = export_request_id || SecureRandom.hex(8)
      @file_path = Rails.root.join('tmp', "epub_export_#{suffix}.epub").to_s
    end

    def generate
      book = Books::EpubBuilder.new(@rich_text_ids, @volume_title, export_request_id: @export_request_id).build
      record_progress('packaging')
      book.generate_epub(@file_path)
      set_filename
      self
    end

    private

    def set_filename
      chapters = chapters_scope.load
      @filename = if chapters.size == 1
                    "#{chapters.first.fiction_title}. #{Books::EpubChapterHtml.title(chapters.first)}.epub"
                  else
                    "#{chapters.first.fiction_title} #{@volume_title}.epub"
                  end
    end

    def chapters_scope
      Books::EpubBuilder.chapters_scope(@rich_text_ids)
    end

    def record_progress(step)
      EpubExportProgress.update!(@export_request_id, step)
    end
  end
end
