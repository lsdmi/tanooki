# frozen_string_literal: true

class CoverContentBuilder
  include Rails.application.routes.url_helpers

  def initialize(chapter)
    @chapter = chapter

    default_url_options[:host] = Rails.env.production? ? 'baka.in.ua' : 'localhost:3000'
  end

  def build
    <<-HTML
      <img src="#{cover_image_url}" alt="#{cover_image_alt}" class="cover-image"/>
      <div class="fiction-title">#{@chapter.fiction_title}</div>
      <div class="display-title">#{chapter_title}</div>
      <div class="author">Автор: <b>#{@chapter.author}</b></div>
      <div class="translator">Переклад: <b>#{translators}</b></div>
      <div class="source">Джерело: <a href="https://baka.in.ua/fictions" target="_blank" rel="noopener noreferrer">Бака</a></div>
      <div class="disclaimer">#{disclaimer_text}</div>
    HTML
  end

  private

  def cover_image_url
    url_for(@chapter.fiction.cover)
  end

  def cover_image_alt
    @chapter.fiction.cover.blob.filename
  end

  def chapter_title
    @chapter.title.presence || @chapter.display_title
  end

  def translators
    @chapter.scanlators.map(&:title).to_sentence
  end

  def disclaimer_text
    I18n.t('cover_generator.disclaimer')
  end
end
