# frozen_string_literal: true

module Chapters
  # Chapter body images stored in Active Storage and linked from the HTML by URL.
  # Production links the permanent CDN URL; other environments link the blob redirect path.
  module Images
    REDIRECT_PATH = %r{/rails/active_storage/blobs/(?:redirect/)?([^/"'?#\s]+)/}
    SRC_ATTRIBUTE = /<img\b[^>]*?\ssrc\s*=\s*(["'])(.*?)\1/im

    module_function

    def service_name
      Rails.configuration.x.chapter_images.service.to_s
    end

    def cdn_host
      Rails.configuration.x.chapter_images.cdn_host
    end

    # Stores an ImageProcessor::Result as an unattached blob.
    def store!(image)
      ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(image.binary), filename: "image.#{image.extension}", content_type: image.content_type,
        service_name:, identify: false,
        metadata: { width: image.width, height: image.height }.compact.merge(identified: true, analyzed: true)
      )
    end

    def url_for(blob)
      return "#{cdn_host}/#{blob.key}" if cdn_host

      Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
    end

    # Chapter image blobs an HTML body links to; any other src is ignored.
    def blobs_in(html)
      urls = html.to_s.scan(SRC_ATTRIBUTE).map(&:last)
      blobs_for_urls(urls)
    end

    def blob_for_url(url)
      blobs_for_urls([url]).first
    end

    def blobs_for_urls(urls)
      keys = urls.filter_map { |url| cdn_key(url) }
      ids = urls.filter_map { |url| redirect_blob_id(url) }
      return ActiveStorage::Blob.none if keys.empty? && ids.empty?

      ActiveStorage::Blob.where(service_name:).where(key: keys).or(
        ActiveStorage::Blob.where(service_name:, id: ids)
      )
    end

    def cdn_key(url)
      return unless cdn_host && url.start_with?("#{cdn_host}/")

      key = url.delete_prefix("#{cdn_host}/").split(/[?#]/, 2).first
      key if key.match?(/\A[a-z0-9]+\z/)
    end

    def redirect_blob_id(url)
      signed_id = url[REDIRECT_PATH, 1]
      signed_id && ActiveStorage::Blob.find_signed(signed_id)&.id
    end
  end
end
