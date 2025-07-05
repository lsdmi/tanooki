# frozen_string_literal: true

# Responsible for fetching HTML content from URLs
class HtmlFetcher
  def fetch_content(url)
    doc = fetch_html_doc(url)
    return ArticleContent.new unless doc

    text = extract_article_text(doc)
    video_url = doc.at_css(BlogScraperConfig.video_iframe_selector)&.[]('src')
    cover_url = fetch_cover_image_url(url)

    ArticleContent.new(
      text: text,
      video_url: video_url,
      cover_url: cover_url
    )
  end

  private

  def fetch_html_doc(url)
    response = Faraday.get(url)
    Nokogiri::HTML(response.body) if response.success?
  rescue StandardError => e
    Rails.logger.error("Failed to fetch HTML for #{url}: #{e.message}")
    nil
  end

  def extract_article_text(doc)
    BlogScraperConfig.article_body_selectors.each do |selector|
      body = doc.at_css(selector)
      return body.search('p').map(&:text).join("\n\n") if body
    end
    nil
  end

  def fetch_cover_image_url(url)
    doc = fetch_html_doc(url)
    doc&.at_css(BlogScraperConfig.cover_image_selector)&.[]('href')
  end
end
