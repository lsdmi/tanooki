# # frozen_string_literal: true

# require 'rss'
# require 'open-uri'
# require 'faraday'
# require 'nokogiri'

# class BlogScraper
#   RSS_URL = 'https://www.cbr.com/feed/category/anime-news/'
#   ARTICLE_BODY_SELECTOR = 'section#article-body'
#   PUBLICATION_TYPE = 'Tale'
#   HIGHLIGHT = true
#   USER_ID = 1

#   def self.fetch_content
#     feed = fetch_rss_feed
#     nil unless feed

#     # feed.items.each do |item|
#     #   process_item(item)
#     # end

#     process_item(feed.items.third)
#   end

#   def self.fetch_rss_feed
#     response = Faraday.get(RSS_URL)
#     return unless response.success?

#     RSS::Parser.parse(response.body, false)
#   rescue StandardError => e
#     Rails.logger.error("Failed to fetch or parse RSS feed: #{e}")
#     nil
#   end

#   def self.process_item(item)
#     article_text, article_image_url = fetch_article_text_and_image(item.link)
#     return unless article_text.present?

#     summary_html = translate_to_ukrainian(article_text, item.title)
#     return unless summary_html.present?

#     # Insert article image after first paragraph, if present
#     summary_html = insert_image_after_first_paragraph(summary_html, article_image_url) if article_image_url

#     title, description = extract_title_and_description(summary_html)
#     return unless title && description

#     publication = build_publication(title, description, item.enclosure&.url)
#     publication.save!
#   rescue StandardError => e
#     Rails.logger.error("Error processing item #{item.link}: #{e}")
#   end

#   # Fetches article text and the first main article image URL
#   def self.fetch_article_text_and_image(url)
#     response = Faraday.get(url)
#     return [nil, nil] unless response.success?

#     doc = Nokogiri::HTML(response.body)
#     content_div = doc.at_css(ARTICLE_BODY_SELECTOR)
#     text = content_div&.search('p')&.map(&:text)&.join("\n\n")

#     # Extract first image from the special div, if present
#     img_div = doc.at_css('div.responsive-img.image-expandable.img-article-item')
#     img_url = img_div&.at_css('img')&.[]('src')

#     [text, img_url]
#   rescue StandardError => e
#     Rails.logger.error("Failed to fetch article text from #{url}: #{e}")
#     [nil, nil]
#   end

#   # Inserts image after the first <p> in the summary HTML
#   def self.insert_image_after_first_paragraph(html, img_url)
#     return html unless img_url

#     doc = Nokogiri::HTML::DocumentFragment.parse(html)
#     img_tag = %(<img style="display: block; margin-left: auto; margin-right: auto;" src="#{img_url}" alt="" width="481px" height="240">)
#     fifth_p = doc.css('p')[4]
#     fifth_p.add_next_sibling(img_tag) if fifth_p
#     doc.to_html
#   end

#   def self.translate_to_ukrainian(article_text, title)
#     client = OpenAI::Client.new(
#       access_token: ENV.fetch('OPENAI_API_KEY'),
#       log_errors: true
#     )

#     prompt = <<~PROMPT
#       Підсумуй цю статтю українською мовою та оформи її у простому HTML.
#       Вимоги:
#       - Поверни лише внутрішній вміст <body> (без тегів <html>, <head>, <body>), без класів, стилів чи будь-яких атрибутів - тільки чисті HTML-теги.
#       - Перший рядок - це заголовок статті у вигляді <h1>.
#       - Підзаголовки повинні бути жирним текстом за допомогою <b>, а не тегів заголовків.
#       - Якщо в статті є списки, не використовуй <ul>, <ol> чи <li>. Замість цього створи марковані списки вручну, використовуючи символ •.
#       - Використовуй базові HTML-елементи для структурування тексту (наприклад, <h1>, <b>, <i>, <p>), але нічого зайвого.

#       НАЗВА (переклади українською): #{title}
#       СТАТТЯ (переклади українською):
#       #{article_text}
#     PROMPT

#     response = client.chat(
#       parameters: {
#         model: 'gpt-4.1',
#         messages: [
#           { role: 'system', content: 'Ти професійний український журналіст та HTML-форматувальник.' },
#           { role: 'user', content: prompt }
#         ],
#         temperature: 0.5
#       }
#     )
#     response.dig('choices', 0, 'message', 'content')
#   rescue StandardError => e
#     Rails.logger.error("OpenAI translation failed: #{e}")
#     nil
#   end

#   def self.extract_title_and_description(html)
#     doc = Nokogiri::HTML.fragment(html)
#     title = doc.at('h1')&.text&.strip
#     description = doc.children.reject { |n| n.name == 'h1' }.map(&:to_html).join.strip
#     [title, description]
#   end

#   def self.build_publication(title, description, cover_url)
#     publication = Publication.new(
#       type: PUBLICATION_TYPE,
#       title: title,
#       description: description,
#       highlight: HIGHLIGHT,
#       user_id: USER_ID
#     )

#     if cover_url.present?
#       cover_file = URI.open(cover_url)
#       publication.cover.attach(
#         io: cover_file,
#         filename: File.basename(URI.parse(cover_url).path)
#       )
#     end

#     publication
#   end
# end
