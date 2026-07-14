# frozen_string_literal: true

module StructuredData
  # JSON-LD payloads for articles, profiles, and videos.
  module JsonLdContentHelper
    def publication_author_profile_url(publication)
      profile_url(
        publication.user.sqid,
        only_path: false,
        **default_public_url_options
      )
    end

    def article_meta(publication)
      {
        '@context': 'https://schema.org',
        '@type': 'NewsArticle',
        headline: publication.title,
        image: [url_for(publication.cover)],
        datePublished: publication.created_at.iso8601,
        dateModified: publication.updated_at.iso8601,
        author: article_author_data(publication)
      }.to_json
    end

    def profile_page_meta(scanlator)
      {
        '@context': 'https://schema.org',
        '@type': 'ProfilePage',
        mainEntity: scanlator_organization_data(scanlator),
        dateCreated: scanlator.created_at.iso8601,
        dateModified: scanlator.updated_at.iso8601
      }.to_json
    end

    def user_profile_meta(user)
      {
        '@context': 'https://schema.org',
        '@type': 'ProfilePage',
        mainEntity: person_data(user),
        dateCreated: user.created_at.iso8601,
        dateModified: user.updated_at.iso8601
      }.to_json
    end

    def video_meta(video)
      {
        '@context': 'https://schema.org',
        '@type': 'VideoObject',
        name: video.title,
        description: video.description.to_plain_text,
        thumbnailUrl: [video.thumbnail],
        uploadDate: video.published_at.iso8601,
        embedUrl: "https://www.youtube.com/embed/#{video.video_id}"
      }.to_json
    end

    private

    def article_author_data(publication)
      {
        '@type': 'Person',
        name: publication.username,
        url: publication_author_profile_url(publication)
      }
    end

    def scanlator_organization_data(scanlator)
      {
        '@type': 'Organization',
        description: scanlator.description,
        identifier: scanlator.slug,
        image: scanlator.avatar.present? ? url_for(scanlator.avatar) : 'scanlator_avatar.webp',
        name: scanlator.title,
        sameAs: [telegram_profile_url(scanlator.telegram_id)]
      }
    end

    def person_data(user)
      {
        '@type': 'Person',
        name: user.name,
        identifier: user.sqid,
        image: user.avatar.image.present? ? url_for(user.avatar.image) : 'user_avatar.webp'
      }.compact
    end
  end
end
