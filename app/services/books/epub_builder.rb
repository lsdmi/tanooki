# frozen_string_literal: true

module Books
  # Builds a GEPUB book from ordered chapter records.
  class EpubBuilder
    def initialize(chapters, volume_title = nil)
      @chapters = Chapter.where(id: chapters.pluck(:id)).released.ordered_by_volume_and_number
      @volume_title = volume_title
    end

    def build
      book = GEPUB::Book.new
      book.ordered do
        add_cover(book)
        add_chapters(book)
      end
      book
    end

    private

    def add_cover(book)
      cover_title = @volume_title || EpubChapterHtml.title(@chapters.first)
      book.add_item('text/cover.xhtml', content: StringIO.new(EpubCoverPage.generate(@chapters.first, cover_title)))
          .landmark(type: 'cover', title: 'Обкладинка')
    end

    def add_chapters(book)
      if @chapters.size == 1
        add_single_chapter(book, @chapters.first)
      else
        add_multiple_chapters(book)
      end
    end

    def add_single_chapter(book, chapter)
      book.add_item('text/content.xhtml')
          .add_content(StringIO.new(EpubChapterHtml.html(chapter)))
          .toc_text(EpubChapterHtml.title(chapter))
          .landmark(type: 'bodymatter', title: EpubChapterHtml.title(chapter))
    end

    def add_multiple_chapters(book)
      @chapters.each_with_index do |chapter, index|
        book.add_item("text/chapter_#{index + 1}.xhtml")
            .add_content(StringIO.new(EpubChapterHtml.html(chapter)))
            .toc_text(EpubChapterHtml.title(chapter))
            .landmark(type: 'bodymatter', title: EpubChapterHtml.title(chapter))
      end
    end
  end
end
