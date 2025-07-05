# frozen_string_literal: true

# Responsible for fetching RSS feeds
class RssFetcher
  def fetch_items
    response = Faraday.get(BlogScraperConfig.rss_url)
    feed = RSS::Parser.parse(response.body, false)
    feed&.items || []
  rescue StandardError => e
    Rails.logger.error("Failed to fetch RSS: #{e.message}")
    []
  end
end
