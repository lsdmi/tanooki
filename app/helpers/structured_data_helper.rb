# frozen_string_literal: true

module StructuredDataHelper
  def article_meta?
    controller_name.to_sym == :tales && action_name.to_sym == :show
  end

  def chapter_reader_meta?
    controller_name.to_sym == :chapters && action_name.to_sym == :show
  end

  def article_author_meta?(publication)
    article_meta? && publication&.persisted?
  end

  # Absolute profile URL for the publication author (meta tags + JSON-LD).
  def publication_author_profile_url(publication)
    profile_url(
      publication.user.sqid,
      only_path: false,
      **Rails.application.config.action_mailer.default_url_options.symbolize_keys
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
      mainEntity: organization_data(scanlator),
      dateCreated: scanlator.created_at.iso8601,
      dateModified: scanlator.updated_at.iso8601
    }.to_json
  end

  def user_profile_meta?
    controller_name.to_sym == :profiles && action_name.to_sym == :show
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

  def video_meta?
    controller_name.to_sym == :youtube_videos && action_name.to_sym == :show
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

  def site_identity_meta
    root = root_url(only_path: false, **default_public_url_options)
    {
      '@context': 'https://schema.org',
      '@graph': [
        {
          '@type': 'WebSite',
          name: 'Бака',
          url: root,
          inLanguage: 'uk-UA',
          publisher: { '@id' => "#{root}#publisher" }
        },
        {
          '@type': 'Organization',
          '@id' => "#{root}#publisher",
          name: 'Бака',
          url: root
        }
      ]
    }.to_json
  end

  def chapter_article_meta(chapter)
    fiction = chapter.fiction
    url = chapter_url(chapter, only_path: false, **default_public_url_options)
    published = (chapter.published_at || chapter.created_at).iso8601
    {
      '@context': 'https://schema.org',
      '@type': 'Article',
      headline: "#{fiction.title} — #{chapter.display_title}",
      image: [url_for(fiction.cover)],
      datePublished: published,
      dateModified: chapter.updated_at.iso8601,
      author: {
        '@type' => 'Person',
        name: fiction.author,
        url: fiction_author_search_url(fiction)
      },
      url:,
      mainEntityOfPage: url
    }.to_json
  end

  private

  def default_public_url_options
    Rails.application.config.action_mailer.default_url_options.symbolize_keys
  end

  def fiction_author_search_url(fiction)
    search_index_url(search: [fiction.author], only_path: false, **default_public_url_options)
  end

  def author_data(publication)
    {
      '@type': 'Person',
      name: publication.username,
      url: publication_author_profile_url(publication)
    }
  end

  def organization_data(scanlator)
    {
      '@type': 'Organization',
      description: scanlator.description,
      identifier: scanlator.slug,
      image: scanlator.avatar.present? ? url_for(scanlator.avatar) : 'scanlator_avatar.webp',
      name: scanlator.title,
      sameAs: ["https://t.me/#{scanlator.telegram_id}"]
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
