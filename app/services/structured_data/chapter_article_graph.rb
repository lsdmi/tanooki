# frozen_string_literal: true

module StructuredData
  # Article JSON-LD for a public chapter reader page.
  module ChapterArticleGraph
    private

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
      }.merge(content_rating_node(fiction))
    end
  end
end
