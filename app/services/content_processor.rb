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

    translated_content = translator.translate(
      article_content.text,
      item.title,
      Tag.all.map { |tag| { id: tag.id, name: tag.name } }
    )
    return unless translated_content

    if article_content.video_url
      video_inserter.insert_video(
        translated_content.html,
        article_content.video_url,
        after_paragraph: BlogScraperConfig.video_insert_after_paragraph
      )
    end

    ProcessedContent.new(
      title: translated_content.title,
      description: translated_content.description,
      cover_url: article_content.cover_url,
      tag_ids: translated_content.tag_ids
    )
  end

  private

  attr_reader :html_fetcher, :translator, :video_inserter
end
