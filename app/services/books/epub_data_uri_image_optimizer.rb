# frozen_string_literal: true

module Books
  # Downscales extracted EPUB image bytes with libvips shrink-on-load.
  module EpubDataUriImageOptimizer
    MAX_EDGE = 600
    JPEG_QUALITY = 80
    MAX_RAW_FALLBACK_BYTES = 100.kilobytes

    module_function

    def optimize_attachment(attachment)
      return [nil, nil] if attachment.nil?
      return [nil, nil] if attachment.respond_to?(:attached?) && !attachment.attached?

      attachment.open { |file| optimize_file(file.path, attachment.blob.content_type) }
    rescue StandardError => e
      Rails.logger.warn("[EPUB] attachment shrink failed: #{e.class}: #{e.message}")
      [nil, nil]
    end

    def optimize_file(path, content_type)
      media_type = content_type.to_s.downcase
      decoded_size = File.size(path)
      return [nil, nil] unless optimizable?(media_type)
      return raw_fallback(path, media_type, decoded_size) unless Attachments::VariantProcessing.available?

      shrink_or_fallback(path, media_type, decoded_size)
    end

    def optimize_data_uri(data_uri)
      tempfile, media_type = decode_data_uri_to_tempfile(data_uri)
      return [nil, nil] unless tempfile

      optimize_tempfile(tempfile, media_type)
    ensure
      tempfile&.close!
    end

    def optimize_data_uri_in_html(html, value_start, value_end)
      media_type, encoded_start = media_type_and_payload_start(html, value_start, value_end)
      return [nil, nil] unless media_type

      decode_and_optimize(html, encoded_start, value_end, media_type)
    end

    def media_type_and_payload_start(html, value_start, value_end)
      comma_idx = html.index(',', value_start)
      return [nil, nil] unless comma_idx && comma_idx < value_end

      header = html[value_start...comma_idx]
      media_type = header.delete_prefix('data:').split(';', 2).first.to_s.downcase
      [media_type, comma_idx + 1]
    end

    def decode_and_optimize(source, encoded_start, encoded_end, media_type)
      tf = Tempfile.new(['epub_src', tempfile_extension(media_type)])
      tf.binmode
      EpubDataUriBase64Io.write_range(source, encoded_start, encoded_end, tf)
      tf.close

      optimize_tempfile(tf, media_type)
    ensure
      tf&.close!
    end

    def decode_data_uri_to_tempfile(data_uri)
      header, encoded = data_uri.split(',', 2)
      return [nil, nil] if encoded.blank?

      media_type = header.delete_prefix('data:').split(';', 2).first.to_s.downcase
      tf = Tempfile.new(['epub_src', tempfile_extension(media_type)])
      tf.binmode
      EpubDataUriBase64Io.write_string(encoded, tf)
      tf.close
      [tf, media_type]
    end

    def optimize_tempfile(tempfile, media_type)
      decoded_size = File.size(tempfile.path)
      return [nil, nil] unless optimizable?(media_type)
      return raw_fallback(tempfile.path, media_type, decoded_size) unless Attachments::VariantProcessing.available?

      shrink_or_fallback(tempfile.path, media_type, decoded_size)
    rescue StandardError => e
      Rails.logger.warn("[EPUB] image shrink failed: #{e.class}: #{e.message}")
      raw_fallback(tempfile.path, media_type, File.size(tempfile.path))
    end

    def shrink_or_fallback(path, media_type, decoded_size)
      jpeg = compress_file(path)
      return [jpeg, 'jpg'] if jpeg.present?

      raw_fallback(path, media_type, decoded_size)
    end

    def compress_file(path)
      require 'vips'

      Vips.cache_set_max(0)
      Vips::Image
        .thumbnail(path, MAX_EDGE, height: MAX_EDGE, size: :down)
        .jpegsave_buffer(Q: JPEG_QUALITY, strip: true, interlace: true)
    end

    def raw_fallback(path, media_type, decoded_size)
      return [nil, nil] if decoded_size > MAX_RAW_FALLBACK_BYTES

      [File.binread(path), extension_for(media_type)]
    end

    def optimizable?(media_type)
      media_type.in?(%w[image/png image/jpeg image/jpg image/webp image/gif image/bmp image/tiff])
    end

    def extension_for(media_type)
      case media_type
      when 'image/jpeg', 'image/jpg' then 'jpg'
      when 'image/png' then 'png'
      when 'image/webp' then 'webp'
      when 'image/gif' then 'gif'
      else 'bin'
      end
    end

    def tempfile_extension(media_type)
      ".#{extension_for(media_type)}"
    end
  end
end
