# frozen_string_literal: true

module StructuredDataHelper
  def article_meta?
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

  def profile_page_meta?
    controller_name.to_sym == :scanlators && action_name.to_sym == :show
  end

  def profile_page_meta(scanlator)
    {
      '@context': 'https://schema.org',
      '@type': 'ProfilePage',
      mainEntity: {
        '@type': 'Organization',
        description: scanlator.description,
        identifier: scanlator.slug,
        image: scanlator.avatar.present? ? url_for(scanlator.avatar) : 'scanlator_avatar.webp',
        name: scanlator.title,
        sameAs: ["https://t.me/#{scanlator.telegram_id}"]
      },
      dateCreated: scanlator.created_at.iso8601,
      dateModified: scanlator.updated_at.iso8601,
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
