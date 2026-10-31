# frozen_string_literal: true

module Meta
  # Renders fiction cover cards as <picture> with AVIF/WebP sources.
  module CoverCardPictureHelper
    PICTURE_ONLY_OPTIONS = %i[lazy srcset sizes picture_html].freeze

    def cover_card_picture_tag(attachment, preset: :card, **options)
      return unless attachment&.attached?

      options = cover_card_img_dimension_options(attachment, preset:, **options)
      picture_options = options.extract!(*PICTURE_ONLY_OPTIONS)
      urls = cover_card_variant_urls(attachment, preset:)
      return image_tag(urls[:fallback], **options.compact) unless urls[:webp]

      cover_card_picture(urls, preset:, **picture_options, **options)
    end

    private

    def cover_card_picture(urls, preset:, **options)
      lazy = options.delete(:lazy)
      srcset = options.delete(:srcset)
      sizes = options.delete(:sizes)
      picture_html = options.delete(:picture_html) || {}
      img_options = cover_card_img_options(urls[:webp], lazy:, **options)
      srcsets = cover_card_srcset_payload(urls, preset:, srcset:, sizes:)

      content_tag(:picture, picture_html) do
        safe_join(cover_card_picture_nodes(urls, lazy, img_options, srcsets))
      end
    end

    def cover_card_srcset_payload(urls, preset:, srcset:, sizes:)
      return {} unless srcset && preset.to_sym == :card

      {
        avif: urls[:avif_srcset],
        webp: urls[:webp_srcset],
        sizes: sizes.presence || CoverCardPresets::CARD_GRID_SIZES
      }
    end

    def cover_card_picture_nodes(urls, lazy, img_options, srcsets)
      [
        cover_card_source_tag(urls[:avif], type: 'image/avif', lazy: lazy,
                                           srcset: srcsets[:avif], sizes: srcsets[:sizes]),
        cover_card_source_tag(urls[:webp], type: 'image/webp', lazy: lazy,
                                           srcset: srcsets[:webp], sizes: srcsets[:sizes]),
        tag.img(**img_options)
      ].compact
    end

    def cover_card_img_dimension_options(attachment, preset:, **options)
      return options if options.key?(:width) && options.key?(:height)

      dimensions = cover_card_display_dimensions(attachment, preset:)
      return options unless dimensions

      options.merge(width: dimensions[0], height: dimensions[1])
    end

    def cover_card_img_options(webp_url, lazy:, **options)
      img_options = options.compact
      img_options[:alt] ||= ''

      if lazy
        img_options[:data] = (img_options[:data] || {}).merge(url: webp_url)
        img_options[:src] = ''
      else
        img_options[:src] = webp_url
      end

      img_options
    end

    def cover_card_source_tag(url, type:, lazy:, srcset: nil, sizes: nil)
      return if url.blank? && srcset.blank?

      descriptor = srcset.presence || url
      attrs = if lazy
                { type: type, data: { srcset: descriptor } }
              else
                { type: type, srcset: descriptor }
              end
      attrs[:sizes] = sizes if sizes.present?
      tag.source(**attrs)
    end
  end
end
