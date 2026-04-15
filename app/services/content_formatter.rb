# frozen_string_literal: true

class ContentFormatter
  class << self
    def html(chapter)
      <<-CONTENT
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml">
        <head>
          <title>#{title(chapter)}</title>
          <style>
            #{css}
          </style>
        </head>
        <body class="epub-content">
          <h1 class="chapter-title">#{title(chapter)}</h1>
          #{format_content(chapter.content.body.to_s)}
        </body>
        </html>
      CONTENT
    end

    def title(chapter)
      chapter.display_title_no_volume || chapter.title.presence
    end

    private

    def css
      @css ||= File.read(Rails.root.join('app', 'assets', 'stylesheets', 'epub_content.css'))
    end

    # EPUB chapter XHTML must use proper empty elements: <hr />, <br />, <img ... /> — not <hr></hr> or <img></img>.
    def format_content(content)
      html = content.to_s
      html = html.gsub(%r{</hr>}i, '').gsub(%r{</br>}i, '')
      html = html.gsub(/&nbsp;/i, '&#160;')
      html = normalize_void_tag(html, 'hr')
      html = normalize_void_tag(html, 'br')
      normalize_img_tag(html)
    end

    def normalize_void_tag(html, tag)
      html.gsub(/<#{tag}\b([^>]*)>/i) do
        raw = Regexp.last_match(1)
        inner = raw.strip.sub(%r{/\s*\z}, '').strip
        inner.empty? ? "<#{tag} />" : "<#{tag} #{inner} />"
      end
    end

    def normalize_img_tag(html)
      html.gsub(/<img\b([^>]*?)>/i) do
        attrs = Regexp.last_match(1).strip
        if attrs.empty?
          '<img />'
        elsif attrs.match?(%r{/\s*\z})
          "<img #{attrs}>"
        else
          "<img #{attrs} />"
        end
      end
    end
  end
end
