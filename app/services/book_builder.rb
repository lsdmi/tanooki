# frozen_string_literal: true

class BookBuilder
  def initialize(chapters, volume_title = nil)
    @chapters = Chapter.where(id: chapters.pluck(:id)).ordered_by_volume_and_number.limit(5)
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
    cover_title = @volume_title || ContentFormatter.title(@chapters.first)
    book.add_item('text/cover.xhtml', content: StringIO.new(CoverGenerator.generate(@chapters.first, cover_title)))
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
        .add_content(StringIO.new(ContentFormatter.html(chapter)))
        .toc_text(ContentFormatter.title(chapter))
        .landmark(type: 'bodymatter', title: ContentFormatter.title(chapter))
  end

  def add_multiple_chapters(book)
    @chapters.each_with_index do |chapter, index|
      book.add_item("text/chapter_#{index + 1}.xhtml")
          .add_content(StringIO.new(ContentFormatter.html(chapter)))
          .toc_text(ContentFormatter.title(chapter))
          .landmark(type: 'bodymatter', title: ContentFormatter.title(chapter))
    end
  end
end
