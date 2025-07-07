# frozen_string_literal: true

# Responsible for processing content from RSS items
class ContentProcessor
  def initialize(
    html_fetcher: HtmlFetcher.new,
    translator: OpenAiTranslator.new,
    video_inserter: VideoInserter.new
  )
    @html_fetcher = html_fetcher
    @translator = translator
    @video_inserter = video_inserter
  end

  def process(item)
    article_content = html_fetcher.fetch_content(item.link)
    return unless article_content.text.present?

    translated_content = translate_content(article_content.text, item.title)
    return unless translated_content

    insert_video_if_needed(translated_content, article_content)

    build_processed_content(translated_content, article_content)
  end

  private

  attr_reader :html_fetcher, :translator, :video_inserter

  def translate_content(text, title)
    translator.translate(
      text,
      title,
      Tag.all.map { |tag| { id: tag.id, name: tag.name } }
    )
  end

  def insert_video_if_needed(translated_content, article_content)
    return unless article_content.video_url

    video_inserter.insert_video(
      translated_content.html,
      article_content.video_url,
      after_paragraph: BlogScraperConfig.video_insert_after_paragraph
    )
  end

  def build_processed_content(translated_content, article_content)
    ProcessedContent.new(
      title: translated_content.title,
      description: translated_content.description,
      cover_url: article_content.cover_url,
      tag_ids: translated_content.tag_ids
    )
  end
end
