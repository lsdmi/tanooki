# frozen_string_literal: true

module Meta
  # Renders fiction cover cards as <picture> with AVIF/WebP sources.
  module CoverCardPictureHelper
    def cover_card_picture_tag(attachment, preset: :card, **)
      return unless attachment&.attached?

      urls = cover_card_variant_urls(attachment, preset:)
      return image_tag(urls[:fallback], **) unless urls[:webp]

      cover_card_picture(urls, **)
    end

    private

    def cover_card_picture(urls, **options)
      lazy = options.delete(:lazy)
      picture_html = options.delete(:picture_html) || {}
      img_options = cover_card_img_options(urls[:webp], lazy:, **options)

      content_tag(:picture, picture_html) do
        safe_join(cover_card_picture_nodes(urls, lazy, img_options))
      end
    end

    def cover_card_picture_nodes(urls, lazy, img_options)
      [
        cover_card_source_tag(urls[:avif], type: 'image/avif', lazy: lazy),
        cover_card_source_tag(urls[:webp], type: 'image/webp', lazy: lazy),
        tag.img(**img_options)
      ].compact
    end

    def cover_card_img_options(webp_url, lazy:, **options)
      img_options = options
      img_options[:alt] ||= ''

      if lazy
        img_options[:data] = (img_options[:data] || {}).merge(url: webp_url)
        img_options[:src] = ''
      else
        img_options[:src] = webp_url
      end

      img_options
    end

    def cover_card_source_tag(url, type:, lazy:)
      return if url.blank?

      if lazy
        tag.source(type: type, data: { srcset: url })
      else
        tag.source(type: type, srcset: url)
      end
    end
  end
end
