# frozen_string_literal: true

class BookBuilder
  def initialize(chapter)
    @chapter = chapter
  end

  def build
    book = GEPUB::Book.new
    book.ordered do
      add_cover(book)
      add_content(book)
    end
    book
  end

  private

  def add_cover(book)
    book.add_item('text/cover.xhtml', content: StringIO.new(CoverGenerator.generate(@chapter)))
        .landmark(type: 'cover', title: 'Обкладинка')
  end

  def add_content(book)
    book.add_item('text/content.xhtml')
        .add_content(StringIO.new(ContentFormatter.html(@chapter)))
        .toc_text(ContentFormatter.title(@chapter))
        .landmark(type: 'bodymatter', title: ContentFormatter.title(@chapter))
  end
end
