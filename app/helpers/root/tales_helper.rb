# frozen_string_literal: true

module Root
  # Card assembly for the home page «Новини та Блоги» editorial grid.
  module TalesHelper
    EDITORIAL_SIDE_COUNT = 2
    EDITORIAL_TALE_LIMIT = EDITORIAL_SIDE_COUNT * 2

    TITLE_LINK_CLASS =
      'rounded-lg font-bold text-white transition-colors hover:text-cyan-300 hover:underline ' \
      'underline-offset-2 dark:hover:text-rose-300 focus:outline-none focus-visible:ring-2 ' \
      'focus-visible:ring-cyan-400 focus-visible:ring-offset-2 focus-visible:ring-offset-gray-900 ' \
      'dark:focus-visible:ring-rose-400'

    COVER_IMAGE_CLASS =
      'h-full w-full object-cover object-center transition-transform duration-300 group-hover/cover:scale-[1.03]'

    def home_tales_editorial_cards(top_tales, tales)
      ordered = top_tales.to_a + tales.to_a
      return { hero: nil, left: [], right: [], side: [] } if ordered.empty?

      hero, *rest = ordered
      left = rest.shift(EDITORIAL_SIDE_COUNT) || []
      right = rest.shift(EDITORIAL_SIDE_COUNT) || []
      { hero: hero, left: left, right: right, side: left + right }
    end

    def home_tales_title_link_class
      TITLE_LINK_CLASS
    end

    def home_tales_cover_picture(publication, preset:)
      cover_card_picture_tag(
        publication.cover,
        preset: preset,
        alt: publication.title,
        picture_html: { class: 'block h-full w-full' },
        class: COVER_IMAGE_CLASS,
        loading: 'lazy'
      )
    end

    def tale_published_date(publication)
      l(publication.created_at, format: :short).downcase
    end
  end
end
