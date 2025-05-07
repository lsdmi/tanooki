# frozen_string_literal: true

class BlogScraper
  RSS_URL = 'https://www.animenewsnetwork.com/all/rss.xml?ann-edition=us'
  ARTICLE_BODY_SELECTOR = 'div.meat'
  REVIEW_BODY_SELECTOR = 'div.KonaBody'
  PUBLICATION_TYPE = 'Tale'
  HIGHLIGHT = true
  USER_ID = 1

  class << self
    # Entry point for fetching and processing blog content.
    def fetch_content(hours: nil, numbers: nil)
      items = fetch_rss_items
      return if items.blank?

      items = filter_items(items, hours: hours, numbers: numbers)
      items.each { |item| process_item(item) }
    end

    private

    # Fetches and parses RSS items from the feed.
    def fetch_rss_items
      response = Faraday.get(RSS_URL)
      feed = RSS::Parser.parse(response.body, false)
      feed&.items || []
    rescue StandardError => e
      Rails.logger.error("Failed to fetch RSS: #{e.message}")
      []
    end

    # Applies time and index filters to RSS items.
    def filter_items(items, hours:, numbers:)
      items = filter_by_time(items, hours) if hours
      items = filter_by_indices(items, numbers) if numbers&.any?
      items
    end

    def filter_by_time(items, hours)
      cutoff = Time.now - (hours * 3600)
      items.select { |item| item.pubDate && item.pubDate >= cutoff }
    end

    def filter_by_indices(items, indices)
      indices.map { |i| items[i] }.compact
    end

    # Processes a single RSS item: fetches, translates, builds, and saves.
    def process_item(item)
      text, video_url = fetch_article_content(item.link)
      return if text.blank?

      all_tags = Tag.all.map { |tag| { id: tag.id, name: tag.name } }
      summary_html_and_tags = translate_to_ukrainian(text, item.title, all_tags)
      return if summary_html_and_tags.blank?

      summary_html, tag_ids = summary_html_and_tags
      summary_html = insert_video(summary_html, video_url, after_paragraph: 2) if video_url

      title, description = extract_title_and_description(summary_html)
      return unless title && description

      cover_url = fetch_cover_image_url(item.link)
      save_publication(title, description, cover_url, tag_ids)
    end

    # Fetches article text and video URL from the article page.
    def fetch_article_content(url)
      doc = fetch_html_doc(url)
      return [nil, nil] unless doc

      text = extract_article_text(doc)
      video_url = extract_video_url(doc)
      [text, video_url]
    end

    def fetch_html_doc(url)
      response = Faraday.get(url)
      return unless response.success?

      Nokogiri::HTML(response.body)
    rescue StandardError => e
      Rails.logger.error("Failed to fetch HTML for #{url}: #{e.message}")
      nil
    end

    def extract_article_text(doc)
      body = doc.at_css(ARTICLE_BODY_SELECTOR)
      body ||= doc.at_css(REVIEW_BODY_SELECTOR)
      body&.search('p')&.map(&:text)&.join("\n\n")
    end

    def extract_video_url(doc)
      doc.at_css('iframe[title="YouTube video player"]')&.[]('src')
    end

    # Fetches the cover image URL from the article page.
    def fetch_cover_image_url(url)
      doc = fetch_html_doc(url)
      doc&.at_css('link[rel="image_src"]')&.[]('href')
    end

    # Inserts a video iframe after a specified paragraph in the HTML.
    def insert_video(html, video_url, after_paragraph:)
      doc = Nokogiri::HTML::DocumentFragment.parse(html)
      target_p = doc.css('p')[after_paragraph]
      return html unless target_p

      iframe = %(<iframe src="#{video_url}" width="100%" height="314" allowfullscreen></iframe>)
      target_p.add_next_sibling(iframe)
      target_p.next_sibling.add_next_sibling('<br>')
      doc.to_html
    end

    # Translates and summarizes the article into Ukrainian HTML.
    def translate_to_ukrainian(article_text, title, tags)
      client = OpenAI::Client.new(
        access_token: ENV.fetch('OPENAI_API_KEY'),
        log_errors: true
      )
      prompt = translation_prompt(article_text, title, tags)
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
      return if content.blank?

      # Extract JSON array of tag IDs from the end of the response
      tag_ids = content.scan(/\[(?:\d+,?\s*)+\]/).last
      tag_ids = tag_ids ? JSON.parse(tag_ids) : []

      # Remove the tag array from the HTML summary if needed
      summary_html = content.sub(/\[(?:\d+,?\s*)+\]\s*\z/, '').strip

      [summary_html, tag_ids]
    rescue StandardError => e
      Rails.logger.error("Translation failed: #{e.message}")
      nil
    end

    # Builds the translation prompt for OpenAI.
    def translation_prompt(article_text, title, tags)
      <<~PROMPT
        Переклади статтю українською мовою та оформи її у простому HTML.
        Вимоги:
        - Поверни лише внутрішній вміст <body> (без тегів <html>, <head>, <body>), без класів, стилів чи будь-яких атрибутів - тільки чисті HTML-теги.
        - Перший рядок - це заголовок статті у вигляді <h1>.
        - Дати в тексті потрібно виділити жирним шрифтом за допомогою <b>.
        - Якщо в статті є списки, не використовуй <ul>, <ol> чи <li>. Замість цього створи марковані списки вручну, використовуючи символ •.
        - Використовуй базові HTML-елементи для структурування тексту (наприклад, <b>, <i>, <p>), але нічого зайвого.

        Ось список можливих тегів для статті у форматі [{id: ..., name: "..."}]:
        #{tags.to_json}

        Вибери всі теги, які найкраще відповідають змісту цієї статті. Обов’язково вибери хоча б один тег.
        Поверни масив id вибраних тегів у форматі JSON у кінці відповіді, наприклад:
        [1, 3, 7]

        НАЗВА (підсумуй українською, має бути короткою та влучною): #{title}
        СТАТТЯ (переклади українською):
        #{article_text}
      PROMPT
    end

    # Extracts title and description from the translated HTML.
    def extract_title_and_description(html)
      doc = Nokogiri::HTML.fragment(html)
      title = doc.at('h1')&.text&.strip
      description = doc.children.reject { |n| n.name == 'h1' }.map(&:to_html).join.strip
      [title, description]
    end

    # Builds and saves the publication record.
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
      Rails.logger.error("Failed to attach cover: #{e.message}")
    end
  end
end
