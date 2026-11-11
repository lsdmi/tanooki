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
        datePublished: publication.public_at.iso8601,
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
        description: scanlator.description.presence&.squish,
        identifier: scanlator.slug,
        image: scanlator_organization_image(scanlator),
        name: scanlator.title,
        sameAs: scanlator_organization_same_as(scanlator)
      }.compact
    end

    def scanlator_organization_image(scanlator)
      if scanlator.avatar.attached?
        rails_blob_url(scanlator.avatar, only_path: false, **default_public_url_options)
      else
        absolute_json_ld_path(asset_path('scanlator_avatar.webp'))
      end
    end

    def scanlator_organization_same_as(scanlator)
      url = telegram_profile_url(scanlator.telegram_id)
      url.present? ? [url] : nil
    end

    def absolute_json_ld_path(path)
      value = path.to_s
      return value if value.match?(%r{\Ahttps?://}i)

      opts = default_public_url_options
      protocol = opts[:protocol].presence || 'http'
      host = opts.fetch(:host)
      port = opts[:port]
      origin = "#{protocol}://#{host}"
      origin = "#{origin}:#{port}" if port.present? && [80, 443].exclude?(port.to_i)
      path_part = value.start_with?('/') ? value : "/#{value}"
      "#{origin}#{path_part}"
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
