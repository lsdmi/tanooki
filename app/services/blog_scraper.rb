# frozen_string_literal: true

class BlogScraper
  RSS_URL = 'https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us'
  ARTICLE_BODY_SELECTORS = ['div.meat', 'div.KonaBody'].freeze
  PUBLICATION_TYPE = 'Tale'
  HIGHLIGHT = true
  USER_ID = 1
  VIDEO_IFRAME_SELECTOR = 'iframe[title="YouTube video player"]'
  COVER_IMAGE_SELECTOR = 'link[rel="image_src"]'

  class << self
    def fetch_content(hours: nil, numbers: nil)
      items = fetch_rss_items
      return if items.blank?

      items = filter_items(items, hours: hours, numbers: numbers)
      items.each { |item| process_item(item) }
    end

    private

    def fetch_rss_items
      response = Faraday.get(RSS_URL)
      feed = RSS::Parser.parse(response.body, false)
      feed&.items || []
    rescue StandardError => e
      log_error('Failed to fetch RSS', e)
      []
    end

    def filter_items(items, hours:, numbers:)
      items = filter_by_time(items, hours) if hours
      items = filter_by_indices(items, numbers) if numbers&.any?
      items
    end

    def filter_by_time(items, hours)
      cutoff = Time.current - hours.hours
      items.select { |item| item.pubDate && item.pubDate >= cutoff }
    end

    def filter_by_indices(items, indices)
      indices.filter_map { |i| items[i] }
    end

    def process_item(item)
      text, video_url = fetch_article_content(item.link)
      return if text.blank?

      all_tags = Tag.all.map { |tag| { id: tag.id, name: tag.name } }
      summary_html, tag_ids = OpenAiTranslator.new(text, item.title, all_tags).translate
      return if summary_html.blank?

      summary_html = insert_video(summary_html, video_url, after_paragraph: 2) if video_url
      title, description = extract_title_and_description(summary_html)
      return unless title && description

      cover_url = fetch_cover_image_url(item.link)
      save_publication(title, description, cover_url, tag_ids)
    end

    def fetch_article_content(url)
      doc = fetch_html_doc(url)
      return [nil, nil] unless doc

      text = extract_article_text(doc)
      video_url = doc.at_css(VIDEO_IFRAME_SELECTOR)&.[]('src')
      [text, video_url]
    end

    def fetch_html_doc(url)
      response = Faraday.get(url)
      Nokogiri::HTML(response.body) if response.success?
    rescue StandardError => e
      log_error("Failed to fetch HTML for #{url}", e)
      nil
    end

    def extract_article_text(doc)
      ARTICLE_BODY_SELECTORS.each do |selector|
        body = doc.at_css(selector)
        return body.search('p').map(&:text).join("\n\n") if body
      end
      nil
    end

    def fetch_cover_image_url(url)
      doc = fetch_html_doc(url)
      doc&.at_css(COVER_IMAGE_SELECTOR)&.[]('href')
    end

    def insert_video(html, video_url, after_paragraph:)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      target_p = doc.css('p')[after_paragraph]
      return html unless target_p

      iframe_html = %(<iframe src="#{video_url}" width="100%" height="314" allowfullscreen></iframe>)
      target_p.add_next_sibling(iframe_html)
      target_p.next_sibling.add_next_sibling('<br>')
      doc.to_html
    end

    def extract_title_and_description(html)
      doc = Nokogiri::HTML.fragment(html)
      title = doc.at('h1')&.text&.strip
      description = doc.children.reject { |n| n.name == 'h1' }.map(&:to_html).join.strip
      [title, description]
    end

    def save_publication(title, description, cover_url, tag_ids)
      publication = Publication.new(
        type: PUBLICATION_TYPE,
        title: title,
        description: description,
        highlight: HIGHLIGHT,
        user_id: USER_ID
      )
      attach_cover(publication, cover_url) if cover_url
      publication.save!

      tag_ids.each { |tag_id| publication.publication_tags.create(tag_id: tag_id) }
    end

    def attach_cover(publication, cover_url)
      cover_file = URI.open(cover_url)
      publication.cover.attach(
        io: cover_file,
        filename: File.basename(URI.parse(cover_url).path)
      )
    rescue StandardError => e
      log_error('Failed to attach cover', e)
    end

    def log_error(message, exception)
      Rails.logger.error("#{message}: #{exception.message}")
    end
  end
end

# Extracted OpenAI translation logic into a service object for DRY and testability
class OpenAiTranslator
  def initialize(article_text, title, tags)
    @article_text = article_text
    @title = title
    @tags = tags
  end

  def translate
    client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY'),
      log_errors: true
    )
    prompt = translation_prompt
    response = client.chat(
      parameters: {
        model: 'gpt-4.1',
        messages: [
          { role: 'system', content: 'Ти професійний український журналіст та HTML-форматувальник.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.5
      }
    )
    content = response.dig('choices', 0, 'message', 'content')
    return [nil, []] if content.blank?

    tag_ids = content.scan(/\[(?:\d+,?\s*)+\]/).last
    tag_ids = tag_ids ? JSON.parse(tag_ids) : []
    summary_html = content.sub(/\[(?:\d+,?\s*)+\]\s*\z/, '').strip

    [summary_html, tag_ids]
  rescue StandardError => e
    Rails.logger.error("Translation failed: #{e.message}")
    [nil, []]
  end

  private

  def translation_prompt
    <<~PROMPT
      Переклади статтю українською мовою та оформи її у простому HTML.
      Вимоги:
      - Поверни лише внутрішній вміст <body> (без тегів <html>, <head>, <body>), без класів, стилів чи будь-яких атрибутів - тільки чисті HTML-теги.
      - Перший рядок - це заголовок статті у вигляді <h1>.
      - Дати в тексті потрібно виділити жирним шрифтом за допомогою <b>.
      - Якщо в статті є списки, не використовуй <ul>, <ol> чи <li>. Замість цього створи марковані списки вручну, використовуючи символ •.
      - Використовуй базові HTML-елементи для структурування тексту (наприклад, <b>, <i>, <p>), але нічого зайвого.

      Ось список можливих тегів для статті у форматі [{id: ..., name: "..."}]:
      #{@tags.to_json}

      Вибери всі теги, які найкраще відповідають змісту цієї статті. Обов’язково вибери хоча б один тег.
      Поверни масив id вибраних тегів у форматі JSON у кінці відповіді, наприклад:
      [1, 3, 7]

      НАЗВА (підсумуй українською, має бути короткою та влучною): #{@title}
      СТАТТЯ (переклади українською):
      #{@article_text}
    PROMPT
  end
end
