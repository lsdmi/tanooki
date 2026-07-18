# frozen_string_literal: true

module Chapters
  # Walks chapter HTML and shrinks oversized inline data-URI images.
  class InlineImagesCompressor
    Result = Data.define(:html, :images_compressed, :before_bytes, :after_bytes)

    def self.compress(html)
      new(html).compress
    end

    def initialize(html)
      @html = html.to_s
    end

    def compress
      output = +''
      pos = 0
      images_compressed = 0

      while (img_start = @html.index('<img', pos))
        scan = scan_img(output, img_start, pos)
        images_compressed += 1 if scan[:compressed]
        pos = scan[:next]
      end

      output << @html[pos..] if pos < @html.length
      build_result(output, images_compressed)
    end

    def build_result(output, images_compressed)
      Result.new(
        html: output,
        images_compressed: images_compressed,
        before_bytes: @html.bytesize,
        after_bytes: output.bytesize
      )
    end

    private

    def scan_img(output, img_start, pos)
      output << @html[pos...img_start]
      tag_end = @html.index('>', img_start)
      return { next: @html.length, compressed: false } unless tag_end

      markup, compressed = transform_tag_at(img_start, tag_end)
      output << markup
      { next: tag_end + 1, compressed: compressed }
    end

    def transform_tag_at(tag_start, tag_end)
      InlineImageTagCompressor.transform_range(@html, tag_start, tag_end)
    end
  end
end
