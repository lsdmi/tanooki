# frozen_string_literal: true

module StructuredData
  # Builds Schema.org JSON-LD graph payloads for site, fiction, chapter, and about pages.
  class EntityGraphs
    include Rails.application.routes.url_helpers

    def initialize(asset_url:)
      @asset_url = asset_url
    end

    def site_identity_json
      site_identity_graph(public_root_url).to_json
    end

    def fiction_book_json(fiction)
      fiction_book_graph(fiction).to_json
    end

    def about_page_json
      about_page_graph.to_json
    end

    def chapter_article_json(chapter)
      chapter_article_graph(chapter).to_json
    end

    private

    def public_root_url
      root_url(only_path: false, **default_public_url_options)
    end

    def site_identity_graph(root)
      {
        '@context': 'https://schema.org',
        '@graph': [SiteProfile.website_node(root), SiteProfile.publisher_organization_data(root)]
      }
    end

    def fiction_book_graph(fiction)
      url = fiction_url(fiction, only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@type': 'Book',
        name: fiction.title,
        author: fiction_author_node(fiction),
        image: [@asset_url.call(fiction.cover)],
        url:,
        inLanguage: 'uk-UA'
      }
    end

    def fiction_author_node(fiction)
      {
        '@type' => 'Person',
        name: fiction.author,
        url: fiction_author_search_url(fiction)
      }
    end

    def about_page_graph
      root = public_root_url
      {
        '@context': 'https://schema.org',
        '@type': 'AboutPage',
        name: 'Про Баку',
        url: about_url(only_path: false, **default_public_url_options),
        description: SiteProfile::DESCRIPTION,
        mainEntity: SiteProfile.publisher_organization_data(root)
      }
    end

    def chapter_article_graph(chapter)
      fiction = chapter.fiction
      url = chapter_url(chapter, only_path: false, **default_public_url_options)
      chapter_article_fields(chapter, fiction, url).merge(
        '@context': 'https://schema.org',
        '@type': 'Article'
      )
    end

    def chapter_article_fields(chapter, fiction, url)
      {
        headline: "#{fiction.title} — #{chapter.display_title}",
        image: [@asset_url.call(fiction.cover)],
        datePublished: (chapter.published_at || chapter.created_at).iso8601,
        dateModified: chapter.updated_at.iso8601,
        author: fiction_author_node(fiction),
        url:,
        mainEntityOfPage: url
      }
    end

    def default_public_url_options
      Rails.application.config.action_mailer.default_url_options.symbolize_keys
    end

    def fiction_author_search_url(fiction)
      search_index_url(search: [fiction.author], only_path: false, **default_public_url_options)
    end
  end
end
