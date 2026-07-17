# frozen_string_literal: true

module Books
  # Builds a GEPUB book from ordered chapter records.
  class EpubBuilder
    def self.chapters_scope(rich_text_ids)
      chapter_ids = ActionText::RichText.where(id: Array(rich_text_ids), record_type: 'Chapter').select(:record_id)

      Chapter.where(id: chapter_ids).released.ordered_by_volume_and_number
    end

    def initialize(rich_text_ids, volume_title = nil, export_request_id: nil)
      @rich_text_ids = Array(rich_text_ids).map(&:to_i)
      @volume_title = volume_title
      @export_request_id = export_request_id
    end

    def build
      record_processing_step('cover')
      book = GEPUB::Book.new
      book.ordered do
        add_cover(book)
        add_chapters(book)
      end
      book
    end

    private

    def chapters_scope
      self.class.chapters_scope(@rich_text_ids)
    end

    def add_cover(book)
      chapter = chapters_scope.first
      cover_title = @volume_title || EpubChapterHtml.title(chapter)
      cover_href = attach_cover_image(book, chapter)
      cover_page = EpubCoverPage.generate(chapter, cover_title, cover_href: cover_href)
      book.add_item('text/cover.xhtml', content: StringIO.new(cover_page))
          .landmark(type: 'cover', title: 'Обкладинка')
      GC.start(full_mark: false)
    end

    def attach_cover_image(book, chapter)
      record_processing_step('cover_image')
      attachment = EpubCoverAttachment.smallest_for(chapter.fiction)
      binary, extension = EpubDataUriImageOptimizer.optimize_attachment(attachment)
      return nil if binary.blank?

      href = "images/cover.#{extension}"
      book.add_item(href, content: StringIO.new(binary))
      "../#{href}"
    rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
      nil
    end

    def add_chapters(book)
      chapter_ids = chapters_scope.pluck(:id)
      if chapter_ids.size == 1
        add_single_chapter(book, Chapter.find(chapter_ids.first))
      else
        add_multiple_chapters(book, chapter_ids)
      end
    end

    def add_single_chapter(book, chapter)
      record_processing_step('chapter 1/1')
      html = chapter_html(book, chapter, 'chapter_1')
      book.add_item('text/content.xhtml')
          .add_content(StringIO.new(html))
          .toc_text(EpubChapterHtml.title(chapter))
          .landmark(type: 'bodymatter', title: EpubChapterHtml.title(chapter))
      GC.start(full_mark: false)
    end

    def add_multiple_chapters(book, chapter_ids)
      chapter_ids.each_with_index do |chapter_id, index|
        add_numbered_chapter(book, chapter_id, index, chapter_ids.size)
      end
    end

    def add_numbered_chapter(book, chapter_id, index, total)
      record_processing_step("chapter #{index + 1}/#{total}")
      chapter = Chapter.find(chapter_id)
      chapter_key = "chapter_#{index + 1}"
      html = chapter_html(book, chapter, chapter_key)
      book.add_item("text/chapter_#{index + 1}.xhtml")
          .add_content(StringIO.new(html))
          .toc_text(EpubChapterHtml.title(chapter))
          .landmark(type: 'bodymatter', title: EpubChapterHtml.title(chapter))
      GC.start(full_mark: false)
    end

    def chapter_html(book, chapter, chapter_key)
      EpubChapterHtml.html(chapter, book: book, chapter_key: chapter_key, export_request_id: @export_request_id)
    end

    def record_processing_step(step)
      EpubExportProgress.update!(@export_request_id, step)
    end
  end
end
