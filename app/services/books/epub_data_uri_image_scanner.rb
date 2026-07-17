# frozen_string_literal: true

module Books
  # Walks chapter HTML and rewrites inline data-URI <img> tags.
  class EpubDataUriImageScanner
    def initialize(html, book:, chapter_key:, export_request_id: nil)
      @html = html
      @book = book
      @chapter_key = chapter_key
      @export_request_id = export_request_id
    end

    def scan
      output = +''
      pos = 0
      index = 0

      while (img_start = @html.index('<img', pos))
        pos = scan_img(output, img_start, pos, index)
        index = pos[:index]
        pos = pos[:next]
      end

      output << @html[pos..] if pos < @html.length
      output
    end

    private

    def scan_img(output, img_start, pos, index)
      output << @html[pos...img_start]
      tag_end = @html.index('>', img_start)
      return { next: @html.length, index: index } unless tag_end

      markup, index = transform_tag_at(img_start, tag_end, index)
      output << markup
      { next: tag_end + 1, index: index }
    end

    def transform_tag_at(tag_start, tag_end, index)
      markup, extracted = EpubDataUriImageTag.transform_range(
        @html,
        tag_start,
        tag_end,
        book: @book,
        chapter_key: @chapter_key,
        index: index,
        export_request_id: @export_request_id
      )
      extracted ? [markup, index + 1] : [markup, index]
    end
  end
end
