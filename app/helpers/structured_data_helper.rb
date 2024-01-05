# frozen_string_literal: true

module StructuredDataHelper
  def structured_data?
    controller_name.to_sym == :tales && action_name.to_sym == :show
  end

  def article_meta(publication)
    {
      '@context': 'https://schema.org',
      '@type': 'NewsArticle',
      headline: publication.title,
      image: [url_for(publication.cover)],
      datePublished: publication.created_at.iso8601,
      dateModified: publication.updated_at.iso8601,
      author: author_data(publication)
    }.to_json
  end

  private

  def author_data(publication)
    {
      '@type': 'Person',
      name: publication.username
    }
  end
end
