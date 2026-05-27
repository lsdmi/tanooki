# frozen_string_literal: true

# Builds inner HTML for an EPUB cover page.
class CoverContentBuilder
  def initialize(chapter, volume_title: nil)
    @chapter = chapter
    @volume_title = volume_title
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
    cover = @chapter.fiction.cover
    alt = ERB::Util.html_escape(cover.blob.filename.to_s)
    src = cover_image_data_uri(cover)
    return '' if src.blank?

    %(<img src="#{src}" alt="#{alt}" class="cover-image"/>)
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
    ''
  end

  def cover_image_data_uri(cover)
    data = cover.download
    encoded = Base64.strict_encode64(data)
    "data:#{cover.blob.content_type};base64,#{encoded}"
  rescue StandardError
    nil
  end

  def chapter_title
    @volume_title || @chapter.title.presence || @chapter.display_title
  end

  def translators
    @chapter.scanlators.map(&:title).to_sentence
  end

  def disclaimer_text
    I18n.t('cover_generator.disclaimer')
  end
end
