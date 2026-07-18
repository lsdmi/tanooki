# frozen_string_literal: true

module Chapters
  # Rewrites one inline data-URI <img> tag with a downscaled JPEG data URI.
  class InlineImageTagCompressor
    Context = Data.define(:html, :tag_start, :tag_end)

    def self.transform_range(html, tag_start, tag_end)
      new(Context.new(html, tag_start, tag_end)).transform_range
    end

    def initialize(context)
      @context = context
    end

    def transform_range
      bounds = data_uri_src_bounds
      return [tag_markup, false] unless bounds

      value_start, value_end = bounds
      return [tag_markup, false] unless oversized?(value_start, value_end)

      binary, extension = InlineImageOptimizer.optimize_data_uri_in_html(
        @context.html, value_start, value_end
      )
      return [tag_markup, false] if binary.blank?

      replace_src(value_start, value_end, binary, extension)
    end

    private

    def replace_src(value_start, value_end, binary, extension)
      prefix = @context.html[@context.tag_start...value_start]
      suffix = @context.html[value_end..@context.tag_end]
      new_tag = prefix + data_uri_for(binary, extension) + suffix
      GC.start(full_mark: false)
      [new_tag, true]
    end

    def data_uri_for(binary, extension)
      media_type = extension == 'jpg' ? 'image/jpeg' : "image/#{extension}"
      "data:#{media_type};base64,#{Base64.strict_encode64(binary)}"
    end

    def oversized?(value_start, value_end)
      encoded_length(value_start, value_end) > ContentLimits::MAX_INLINE_DATA_URI_ENCODED_BYTES
    end

    def encoded_length(value_start, value_end)
      comma_idx = @context.html.index(',', value_start)
      return 0 unless comma_idx && comma_idx < value_end

      base64_idx = @context.html.index('base64,', value_start)
      return 0 unless base64_idx && base64_idx <= value_end

      value_end - (base64_idx + ContentLimits::BASE64_MARKER.length)
    end

    def tag_markup
      @context.html[@context.tag_start..@context.tag_end]
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
