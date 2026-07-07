# frozen_string_literal: true

module Root
  # Card fields for the home page «Популярне ранобе» strip.
  module PopularFictionsHelper
    def popular_fiction_card_stats(fiction)
      {
        views: format_view_count(fiction.views),
        rating: formatted_fiction_rating(fiction),
        genres: popular_fiction_genre_links(fiction)
      }
    end

    private

    def formatted_fiction_rating(fiction)
      return '—' unless fiction.average_rating.positive?

      number_with_precision(fiction.average_rating, precision: 1)
    end

    def popular_fiction_genre_links(fiction)
      fiction.genres.sort_by(&:name).first(2).map { |genre| { name: genre.name, slug: genre.slug } }
    end
  end
end
