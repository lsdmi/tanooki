# frozen_string_literal: true

module Fictions
  # Featured-card copy for «Гарячі Новинки» on the fictions index.
  module HotNoveltyHelper
    def hot_novelty_featured_copy(fiction, released_chapter_count)
      {
        rating: hot_novelty_rating(fiction),
        views: format_view_count(fiction.views),
        status: hot_novelty_status_label(fiction),
        chapters: released_chapter_count.to_i,
        excerpt: hot_novelty_excerpt(fiction),
        genres: hot_novelty_genres(fiction)
      }
    end

    private

    def hot_novelty_genres(fiction)
      adults, regular = fiction.genres.partition { |genre| Genre.adult_tag?(genre.name, slug: genre.slug) }
      (adults + regular).first(3).map { |genre| { name: genre.name, slug: genre.slug } }
    end

    def hot_novelty_rating(fiction)
      return '—' unless fiction.average_rating.positive?

      number_with_precision(fiction.average_rating, precision: 1)
    end

    def hot_novelty_status_label(fiction)
      (Fiction.statuses[fiction.status] || fiction.status).to_s
    end

    def hot_novelty_excerpt(fiction)
      truncate(strip_tags(fiction.description.to_s), length: 280, separator: ' ')
    end
  end
end
