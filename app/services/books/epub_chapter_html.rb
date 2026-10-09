# frozen_string_literal: true

module Books
  # Wraps a chapter in EPUB-safe XHTML (void tags, embedded +epub_content.css+).
  class EpubChapterHtml
    LARGE_CONTENT_BYTES = 1.megabyte
    # style="…" and the quote that wraps the value.
    STYLE_ATTRIBUTE = /\sstyle\s*=\s*("[^"]*"|'[^']*')/i
    # font shorthand is included: it sets family and size. font-weight and background-color do not match.
    HAS_READER_OWNED_STYLE = /font-family\s*:|font-size\s*:|line-height\s*:|(?<![\w-])color\s*:|(?<![\w-])font\s*:/i
    READER_OWNED_DECLARATION = /(?:\A|;)\s*(?:font(?:-family|-size)?|line-height|color)\s*:\s*[^;]*/i

    class << self
      def html(chapter, book: nil, chapter_key: 'chapter', export_request_id: nil)
        xhtml_document(
          title(chapter),
          chapter_html_body(chapter, book: book, chapter_key: chapter_key, export_request_id: export_request_id)
        )
      end

      def xhtml_document(chapter_title, body)
        <<-CONTENT
        <!DOCTYPE html>
        <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
        <head>
          <title>#{chapter_title}</title>
          <style>
            #{css}
          </style>
        </head>
        <body class="epub-content">
          <h1 class="chapter-title">#{chapter_title}</h1>
          #{body}
        </body>
        </html>
        CONTENT
      end

      def chapter_html_body(chapter, book:, chapter_key:, export_request_id: nil)
        body = chapter_body_html(chapter)
        if book
          body = EpubDataUriImages.extract!(
            body,
            book: book,
            chapter_key: chapter_key,
            export_request_id: export_request_id
          )
        end
        format_content(body)
      end

      def title(chapter)
        chapter.display_title_no_volume || chapter.title.presence
      end

      private

      def chapter_body_html(chapter)
        # Read stored HTML directly; Action Text rendering can timeout on huge inline images.
        EpubChapterBodies.raw_html(chapter)
      end

      def css
        @css ||= Rails.root.join('app/assets/stylesheets/epub_content.css').read
      end

      # EPUB chapter XHTML must use proper empty elements: <hr />, <br />, <img ... /> — not <hr></hr> or <img></img>.
      # Inline font, size, line-height, and color are stripped here, including for very large chapters.
      # The stored HTML is not rewritten; the book stylesheet owns those four.
      def format_content(content)
        html = UserContent::ExplanationNotes.call(content.to_s)
        html = EpubFootnotes.call(html)
        html = strip_reader_owned_styles(html)
        html = html.gsub('</hr>', '').gsub('</br>', '').gsub('</HR>', '').gsub('</BR>', '')
        html = html.gsub('&nbsp;', '&#160;').gsub('&NBSP;', '&#160;')
        return html if html.bytesize >= LARGE_CONTENT_BYTES

        html = normalize_void_tag(html, 'hr')
        html = normalize_void_tag(html, 'br')
        normalize_img_tag(html)
      end

      def strip_reader_owned_styles(html)
        return html unless html.match?(HAS_READER_OWNED_STYLE)

        html.gsub(STYLE_ATTRIBUTE) do
          quoted = Regexp.last_match(1)
          value = quoted[1..-2]
          next Regexp.last_match(0) unless value.match?(READER_OWNED_DECLARATION)

          quote = quoted[0]
          cleaned = value.gsub(READER_OWNED_DECLARATION, '')
          cleaned = cleaned.sub(/\A\s*;\s*/, '').gsub(/;\s*;/, ';').strip.sub(/;\s*\z/, '')
          cleaned.empty? ? '' : %( style=#{quote}#{cleaned}#{quote})
        end
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
end
