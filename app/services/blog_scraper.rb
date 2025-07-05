# frozen_string_literal: true

# Main orchestrator class that coordinates the blog scraping process
class BlogScraper
  # Class method for backward compatibility and simple usage
  def self.fetch_content(numbers: nil)
    new.fetch_content(numbers: numbers)
  end

  def initialize(
    rss_fetcher: RssFetcher.new,
    content_processor: ContentProcessor.new,
    publication_creator: PublicationCreator.new,
    logger: Rails.logger
  )
    @rss_fetcher = rss_fetcher
    @content_processor = content_processor
    @publication_creator = publication_creator
    @logger = logger
  end

  def fetch_content(numbers: nil)
    items = @rss_fetcher.fetch_items
    return if items.blank?

    items = filter_by_indices(items, numbers) if numbers&.any?
    items.each { |item| process_item(item) }
  end

  private

  attr_reader :rss_fetcher, :content_processor, :publication_creator, :logger

  def filter_by_indices(items, indices)
    indices.filter_map { |i| items[i] }
  end

  def process_item(item)
    processed_content = content_processor.process(item)
    return unless processed_content

    publication_creator.create(processed_content)
  rescue StandardError => e
    logger.error("Failed to process item: #{e.message}")
  end
end
