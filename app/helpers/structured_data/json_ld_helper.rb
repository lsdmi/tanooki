# frozen_string_literal: true

module StructuredData
  # Schema.org JSON-LD payloads and script tags for layout and Open Graph meta.
  module JsonLdHelper
    def json_ld_script(json_payload)
      # JSON must not be HTML-escaped inside script tags; guard only against </script> breaks.
      safe_payload = json_payload.to_s.gsub('</', '<\\/')
      tag.script(safe_payload.html_safe, type: 'application/ld+json')
    end

    def article_meta?
      tales_show_page?
    end

    def chapter_reader_meta?
      chapters_show_page?
    end

    def fiction_reader_meta?
      fictions_show_page?
    end

    def about_page_meta?
      pages_about_page?
    end

    def article_author_meta?(publication)
      tales_show_page? && publication&.persisted?
    end

    def fiction_author_meta?(fiction)
      fiction_reader_meta? && fiction&.persisted?
    end

    def fiction_author_url(fiction)
      fiction_author_search_url(fiction)
    end

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

    def profile_page_meta?
      scanlators_show_page?
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

    def user_profile_meta?
      profiles_show_page?
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
      youtube_videos_show_page?
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
          publisher_organization_data(root)
        ]
      }.to_json
    end

    def fiction_book_meta(fiction)
      url = fiction_url(fiction, only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@type': 'Book',
        name: fiction.title,
        author: {
          '@type' => 'Person',
          name: fiction.author,
          url: fiction_author_search_url(fiction)
        },
        image: [url_for(fiction.cover)],
        url:,
        inLanguage: 'uk-UA'
      }.to_json
    end

    def about_page_meta
      root = root_url(only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@type': 'AboutPage',
        name: 'Про Баку',
        url: about_url(only_path: false, **default_public_url_options),
        description: StructuredData::SiteProfile::DESCRIPTION,
        mainEntity: publisher_organization_data(root)
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

    def tales_show_page?
      controller_name.to_sym == :tales && action_name.to_sym == :show
    end

    def chapters_show_page?
      controller_name.to_sym == :chapters && action_name.to_sym == :show
    end

    def fictions_show_page?
      controller_name.to_sym == :fictions && action_name.to_sym == :show
    end

    def pages_about_page?
      controller_name.to_sym == :pages && action_name.to_sym == :about
    end

    def scanlators_show_page?
      controller_name.to_sym == :scanlators && action_name.to_sym == :show
    end

    def profiles_show_page?
      controller_name.to_sym == :profiles && action_name.to_sym == :show
    end

    def youtube_videos_show_page?
      controller_name.to_sym == :youtube_videos && action_name.to_sym == :show
    end

    def default_public_url_options
      Rails.application.config.action_mailer.default_url_options.symbolize_keys
    end

    def fiction_author_search_url(fiction)
      search_index_url(search: [fiction.author], only_path: false, **default_public_url_options)
    end

    def publisher_organization_data(root)
      {
        '@type': 'Organization',
        '@id' => "#{root}#publisher",
        name: StructuredData::SiteProfile::NAME,
        url: root,
        description: StructuredData::SiteProfile::DESCRIPTION,
        foundingDate: StructuredData::SiteProfile::FOUNDING_YEAR,
        sameAs: StructuredData::SiteProfile::SOCIAL_URLS,
        knowsAbout: StructuredData::SiteProfile::EXPERTISE_TOPICS
      }
    end

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
end
