# frozen_string_literal: true

module Books
  # Parses one <img> tag and swaps an inline data URI for an EPUB manifest asset.
  class EpubDataUriImageTag
    TransformContext = Data.define(:html, :tag_start, :tag_end, :book, :chapter_key, :index, :export_request_id)

    def self.transform_range(html, tag_start, tag_end, book:, chapter_key:, index:, export_request_id: nil) # rubocop:disable Metrics/ParameterLists
      context = TransformContext.new(html, tag_start, tag_end, book, chapter_key, index, export_request_id)
      new(context).transform_range
    end

    def self.transform(tag, book:, chapter_key:, index:, export_request_id: nil)
      context = TransformContext.new(tag, 0, tag.length - 1, book, chapter_key, index, export_request_id)
      new(context).transform_range
    end

    def initialize(context)
      @context = context
    end

    def transform_range
      bounds = data_uri_src_bounds
      return [tag_markup, false] unless bounds

      value_start, value_end = bounds
      EpubExportProgress.update!(@context.export_request_id, "#{@context.chapter_key} image #{@context.index}")

      binary, extension = EpubDataUriImageOptimizer.optimize_data_uri_in_html(
        @context.html, value_start, value_end
      )
      return [missing_image_markup, false] if binary.blank?

      attach_image(binary, extension, value_start, value_end)
    end

    private

    def attach_image(binary, extension, value_start, value_end)
      href = "images/#{@context.chapter_key}_#{@context.index}.#{extension}"
      @context.book.add_item(href, content: StringIO.new(binary))
      GC.start(full_mark: false)

      prefix = @context.html[@context.tag_start...value_start]
      suffix = @context.html[value_end..@context.tag_end]
      new_tag = prefix + "../#{href}" + suffix
      [new_tag, true]
    end

    def tag_markup
      @context.html[@context.tag_start..@context.tag_end]
    end

    def missing_image_markup
      tag = tag_markup
      alt = tag[/\balt=(["'])(.*?)\1/i, 2]
      label = alt.present? ? ERB::Util.html_escape(alt) : 'Зображення'
      %(<p class="epub-missing-image">[#{label}]</p>)
    end

    def data_uri_src_bounds
      offset = @context.tag_start
      while (src_idx = @context.html.index('src', offset))
        break if src_idx > @context.tag_end

        result, next_offset = scan_src_at(src_idx)
        return result if result

        offset = next_offset
      end

      nil
    end

    def scan_src_at(src_idx)
      return [nil, src_idx + 3] unless src_attribute?(src_idx)

      bounds = quoted_value_bounds(src_idx)
      return [nil, src_idx + 3] unless bounds

      value_start, value_end = bounds
      return [[value_start, value_end], value_end + 1] if data_uri_at?(value_start, value_end)

      [nil, value_end + 1]
    end

    def quoted_value_bounds(src_idx)
      eq_idx = @context.html.index('=', src_idx)
      quote_idx = eq_idx && @context.html.index(/["']/, eq_idx)
      return nil unless quote_idx && quote_idx <= @context.tag_end

      quote = @context.html[quote_idx]
      value_start = quote_idx + 1
      value_end = @context.html.index(quote, value_start)
      return nil unless value_end && value_end <= @context.tag_end

      [value_start, value_end]
    end

    def src_attribute?(src_idx)
      before = src_idx <= @context.tag_start ? ' ' : @context.html[src_idx - 1]
      after_idx = src_idx + 3
      return false if after_idx > @context.tag_end

      after = @context.html[after_idx]
      before.match?(%r{[\s>/]}) && (after.nil? || after.match?(%r{[\s=/]}))
    end

    def data_uri_at?(value_start, value_end)
      return false unless @context.html[value_start, 5] == 'data:'

      base64_idx = @context.html.index('base64,', value_start)
      base64_idx && base64_idx <= value_end
    end
  end
end
