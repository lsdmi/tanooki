# frozen_string_literal: true

module Books
  # Renders a complete EPUB cover XHTML document for a chapter.
  class EpubCoverPage
    def self.generate(chapter, volume_title = nil, cover_href: nil)
      new(chapter, volume_title, cover_href:).generate
    end

    def initialize(chapter, volume_title = nil, cover_href: nil)
      @chapter = chapter
      @volume_title = volume_title
      @cover_href = cover_href
    end

    def generate
      render_html
    end

    private

    attr_reader :chapter, :volume_title

    def render_html
      <<-HTML
      <!DOCTYPE html>
      <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <title>#{title}</title>
        <style>
          #{cover_styles}
        </style>
      </head>
      <body class="epub-cover">
        <div class="container">
          #{cover_content}
        </div>
      </body>
      </html>
      HTML
    end

    def title
      volume_title || chapter.title
    end

    def cover_styles
      @cover_styles ||= Rails.root.join('app/assets/stylesheets/epub_cover.css').read
    end

    def cover_content
      EpubCoverContent.new(chapter, volume_title:, cover_href: @cover_href).build
    end
  end
end
