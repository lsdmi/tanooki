# frozen_string_literal: true

module Contests
  # Gallery card for an accepted contest entry, matching a storage catalog card.
  class EntryCardComponent < ViewComponent::Base
    include Meta::CoverUrlsHelper

    def initialize(entry:, blur_eighteen: false, plain: false)
      super()
      @entry = entry
      @fiction = entry.fiction
      @blur_eighteen = blur_eighteen
      @plain = plain
    end

    def render?
      fiction.present?
    end

    private

    attr_reader :entry, :fiction, :blur_eighteen, :plain

    def plain? = plain

    def blur?
      blur_eighteen && fiction.content_rating_eighteen?
    end

    def href
      helpers.fiction_path(fiction)
    end

    def age_label
      fiction.content_rating_label
    end

    def rating_text
      rating = fiction.average_rating.to_f
      return unless rating.positive?

      helpers.number_with_precision(rating, precision: 1, separator: ',')
    end

    def genre_slugs
      @genre_slugs ||= fiction.genres.sort_by(&:name).to_h { |genre| [genre.name, genre.slug] }
    end

    def genre_labels
      Genre.sort_labels_adult_first(genre_slugs.keys, slugs: genre_slugs).first(2)
    end

    def genre_href(name)
      slug = genre_slugs[name]
      helpers.fiction_genre_fictions_path(slug) if slug.present?
    end

    def cover_class
      [
        'absolute inset-0 h-full w-full object-cover transition-transform duration-200 ease-out',
        'group-hover/cover:scale-[1.02]',
        ('blur-md scale-105' if blur?)
      ].compact.join(' ')
    end

    def age_class
      if fiction.content_rating_eighteen?
        'token-raw border border-rose-700/60 bg-rose-100/80 text-rose-900 ' \
          'token-raw dark:border-rose-400/50 dark:bg-rose-950/70 dark:text-rose-100'
      else
        'token-raw border border-amber-800/60 bg-amber-100/80 text-amber-950 ' \
          'token-raw dark:border-amber-400/50 dark:bg-amber-950/70 dark:text-amber-100'
      end
    end
  end
end
