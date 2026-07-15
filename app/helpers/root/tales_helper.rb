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

    def home_tales_editorial_cards(top_tale, tales)
      return home_tales_empty_editorial if top_tale.blank? && tales.blank?

      hero = top_tale || tales.first
      { hero: hero, **home_tales_editorial_columns(home_tales_side_tales(tales, hero)) }
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

    def home_tales_empty_editorial
      { hero: nil, left: [], right: [], side: [] }
    end

    def home_tales_side_tales(tales, hero)
      tales.to_a
           .reject { |tale| tale == hero }
           .uniq
           .sort_by(&:created_at)
           .reverse
           .first(EDITORIAL_TALE_LIMIT)
    end

    def home_tales_editorial_columns(side)
      left = side.first(EDITORIAL_SIDE_COUNT) || []
      right = side.drop(EDITORIAL_SIDE_COUNT).first(EDITORIAL_SIDE_COUNT) || []
      { left: left, right: right, side: left + right }
    end
  end
end
