# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'faraday'
require 'nokogiri'
require 'time'

class BlogScraper
  RSS_URL = 'https://www.cbr.com/feed/category/anime-news/'
  ARTICLE_BODY_SELECTOR = 'section#article-body'
  PUBLICATION_TYPE = 'Tale'
  HIGHLIGHT = true
  USER_ID = 1

  def self.fetch_content(hours: nil, numbers: nil)
    feed = fetch_rss_feed
    return unless feed

    items = feed.items

    # Filter by hours if given
    if hours
      cutoff_time = Time.now - (hours * 3600)
      items = items.select do |item|
        pub_date = item.pubDate
        pub_date && pub_date >= cutoff_time
      end
    end

    # Filter by indices if given (overrides hours if both are present)
    items = numbers.map { |i| items[i] }.compact if numbers&.any?

    items.each do |item|
      process_item(item)
    end
  end

  def self.fetch_rss_feed
    response = HTTPX.get(RSS_URL)

    if response.is_a?(HTTPX::ErrorResponse)
      Rails.logger.error("HTTPX ErrorResponse: #{response.inspect}")
      Rails.logger.error("Raw body: #{response.body.inspect}")
      return
    end

    unless response.status == 200
      Rails.logger.error("Failed to fetch RSS feed: HTTP #{response.status}, headers: #{response.headers.inspect}")
      Rails.logger.error("Body: #{response.body[0..1000]}") # log the first 1000 chars
      return
    end

    begin
      RSS::Parser.parse(response.body, false)
    rescue RSS::NotWellFormedError => e
      Rails.logger.error("Failed to parse RSS feed: #{e.class} - #{e.message}")
      Rails.logger.error("Raw response body (first 2000 chars):\n#{response.body[0..1999]}")
      # Optionally, write the body to a file for inspection:
      begin
        File.write('/tmp/rss_debug.xml', response.body)
      rescue StandardError
        nil
      end
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Failed to fetch or parse RSS feed: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.join("\n")) if e.backtrace
    nil
  end

  def self.process_item(item)
    article_text, article_image_url = fetch_article_text_and_image(item.link)
    return unless article_text.present?

    summary_html = translate_to_ukrainian(article_text, item.title)
    return unless summary_html.present?

    summary_html = insert_image_after_nth_paragraph(summary_html, article_image_url, 2) if article_image_url

    title, description = extract_title_and_description(summary_html)
    return unless title && description

    publication = build_publication(title, description, item.enclosure&.url)
    publication.save!
  rescue StandardError => e
    Rails.logger.error("Error processing item #{item.link}: #{e}")
  end

  def self.fetch_article_text_and_image(url)
    response = Faraday.get(url)
    return [nil, nil] unless response.success?

    doc = Nokogiri::HTML(response.body)
    content_div = doc.at_css(ARTICLE_BODY_SELECTOR)
    text = content_div&.search('p')&.map(&:text)&.join("\n\n")

    # Extract first image from the special div, if present
    img_div = doc.at_css('div.responsive-img.image-expandable.img-article-item')
    img_url = img_div&.at_css('img')&.[]('src')

    [text, img_url]
  rescue StandardError => e
    Rails.logger.error("Failed to fetch article text from #{url}: #{e}")
    [nil, nil]
  end

  # Inserts image after the nth <p> in the summary HTML (n is 0-based)
  def self.insert_image_after_nth_paragraph(html, img_url, n)
    return html unless img_url

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    nth_p = doc.css('p')[n]

    if nth_p
      img_tag = %(<img style="display: block; margin-left: auto; margin-right: auto;" src="#{img_url}" alt="" width="712px" height="430px">)
      br_tag = '<br>'
      nth_p.add_next_sibling(img_tag)
      nth_p.next_sibling.add_next_sibling(br_tag)
    end

    doc.to_html
  end

  def self.translate_to_ukrainian(article_text, title)
    client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY'),
      log_errors: true
    )

    prompt = <<~PROMPT
      Підсумуй цю статтю українською мовою та оформи її у простому HTML.
      Вимоги:
      - Поверни лише внутрішній вміст <body> (без тегів <html>, <head>, <body>), без класів, стилів чи будь-яких атрибутів - тільки чисті HTML-теги.
      - Перший рядок - це заголовок статті у вигляді <h1>.
      - Підзаголовки повинні бути жирним текстом за допомогою <b>, а не тегів заголовків.
      - Якщо в статті є списки, не використовуй <ul>, <ol> чи <li>. Замість цього створи марковані списки вручну, використовуючи символ •.
      - Використовуй базові HTML-елементи для структурування тексту (наприклад, <h1>, <b>, <i>, <p>), але нічого зайвого.

      НАЗВА (переклади українською): #{title}
      СТАТТЯ (переклади українською):
      #{article_text}
    PROMPT

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
    response.dig('choices', 0, 'message', 'content')
  rescue StandardError => e
    Rails.logger.error("OpenAI translation failed: #{e}")
    nil
  end

  def self.extract_title_and_description(html)
    doc = Nokogiri::HTML.fragment(html)
    title = doc.at('h1')&.text&.strip
    description = doc.children.reject { |n| n.name == 'h1' }.map(&:to_html).join.strip
    [title, description]
  end

  def self.build_publication(title, description, cover_url)
    publication = Publication.new(
      type: PUBLICATION_TYPE,
      title: title,
      description: description,
      highlight: HIGHLIGHT,
      user_id: USER_ID
    )

    if cover_url.present?
      cover_file = URI.open(cover_url)
      publication.cover.attach(
        io: cover_file,
        filename: File.basename(URI.parse(cover_url).path)
      )
    end

    publication
  end
end
