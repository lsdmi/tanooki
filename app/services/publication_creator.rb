# frozen_string_literal: true

# Responsible for creating publications
class PublicationCreator
  def create(processed_content)
    return unless processed_content.title && processed_content.description

    publication = Publication.new(
      type: BlogScraperConfig.publication_type,
      title: processed_content.title,
      description: processed_content.description,
      highlight: BlogScraperConfig.highlight,
      user_id: BlogScraperConfig.user_id
    )

    attach_cover(publication, processed_content.cover_url) if processed_content.cover_url
    publication.save!

    processed_content.tag_ids.each { |tag_id| publication.publication_tags.create(tag_id: tag_id) }

    publication
  rescue StandardError => e
    Rails.logger.error("Failed to create publication: #{e.message}")
    nil
  end

  private

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
