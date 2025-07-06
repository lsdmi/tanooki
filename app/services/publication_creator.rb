# frozen_string_literal: true

# Responsible for creating publications
class PublicationCreator
  def create(processed_content)
    return unless processed_content.title && processed_content.description

    publication = build_publication(processed_content)
    attach_cover(publication, processed_content.cover_url) if processed_content.cover_url
    publication.save!
    create_publication_tags(publication, processed_content.tag_ids)

    publication
  rescue StandardError => e
    Rails.logger.error("Failed to create publication: #{e.message}")
    nil
  end

  private

  def build_publication(processed_content)
    Publication.new(
      type: BlogScraperConfig.publication_type,
      title: processed_content.title,
      description: processed_content.description,
      highlight: BlogScraperConfig.highlight,
      user_id: BlogScraperConfig.user_id
    )
  end

  def create_publication_tags(publication, tag_ids)
    tag_ids.each { |tag_id| publication.publication_tags.create(tag_id: tag_id) }
  end

  def attach_cover(publication, cover_url)
    uri = URI.parse(cover_url)
    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    publication.cover.attach(
      io: StringIO.new(response.body),
      filename: File.basename(uri.path)
    )
  rescue StandardError => e
    Rails.logger.error("Failed to attach cover: #{e.message}")
  end
end
