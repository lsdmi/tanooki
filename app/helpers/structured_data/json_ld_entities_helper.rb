# frozen_string_literal: true

module StructuredData
  # JSON-LD payloads for site, fiction, chapter, and about pages.
  module JsonLdEntitiesHelper
    def site_identity_meta
      site_identity_graph(public_root_url).to_json
    end

    def fiction_book_meta(fiction)
      fiction_book_graph(fiction).to_json
    end

    def about_page_meta
      about_page_graph.to_json
    end

    def chapter_article_meta(chapter)
      chapter_article_graph(chapter).to_json
    end

    private

    def public_root_url
      root_url(only_path: false, **default_public_url_options)
    end

    def site_identity_graph(root)
      {
        '@context': 'https://schema.org',
        '@graph': [website_node(root), publisher_organization_data(root)]
      }
    end

    def website_node(root)
      {
        '@type': 'WebSite',
        name: 'Бака',
        url: root,
        inLanguage: 'uk-UA',
        publisher: { '@id' => "#{root}#publisher" }
      }
    end

    def fiction_book_graph(fiction)
      url = fiction_url(fiction, only_path: false, **default_public_url_options)
      {
        '@context': 'https://schema.org',
        '@type': 'Book',
        name: fiction.title,
        author: fiction_author_node(fiction),
        image: [url_for(fiction.cover)],
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
        description: StructuredData::SiteProfile::DESCRIPTION,
        mainEntity: publisher_organization_data(root)
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
        image: [url_for(fiction.cover)],
        datePublished: (chapter.published_at || chapter.created_at).iso8601,
        dateModified: chapter.updated_at.iso8601,
        author: fiction_author_node(fiction),
        url:,
        mainEntityOfPage: url
      }
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
  end
end
