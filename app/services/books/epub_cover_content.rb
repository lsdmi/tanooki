# frozen_string_literal: true

module Books
  # Builds inner HTML for an EPUB cover page.
  class EpubCoverContent
    def initialize(chapter, volume_title: nil, cover_href: nil)
      @chapter = chapter
      @volume_title = volume_title
      @cover_href = cover_href
    end

    def build
      <<-HTML
      #{cover_image_tag}
      <div class="fiction-title">#{@chapter.fiction_title}</div>
      <div class="display-title">#{chapter_title}</div>
      <div class="author">Автор: <b>#{@chapter.author}</b></div>
      <div class="translator">Переклад: <b>#{translators}</b></div>
      <div class="source">Джерело: <a href="https://baka.in.ua/fictions" target="_blank" rel="noopener noreferrer">Бака</a></div>
      <div class="disclaimer">#{disclaimer_text}</div>
      HTML
    end

    private

    def cover_image_tag
      return '' if @cover_href.blank?

      alt = ERB::Util.html_escape(@chapter.fiction_title)
      %(<img src="#{@cover_href}" alt="#{alt}" class="cover-image"/>)
    end

    def chapter_title
      @volume_title || @chapter.title.presence || @chapter.display_title
    end

    def translators
      @chapter.scanlators.map(&:title).to_sentence
    end

    def disclaimer_text
      I18n.t('books.epub_cover.disclaimer')
    end
  end
end
