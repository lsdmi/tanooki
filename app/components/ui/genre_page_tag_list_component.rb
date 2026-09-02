# frozen_string_literal: true

module Ui
  # Row of genre pills on featured genre-page cards (outline in light mode, slate on dark panel).
  class GenrePageTagListComponent < ViewComponent::Base
    def initialize(genres:, **options)
      super()
      @genres = sorted_genres(Array(genres).compact_blank)
      @html = options.fetch(:html, {})
      @tag_html = options.fetch(:tag_html, {})
      @pin_bottom = options.fetch(:pin_bottom, true)
      @compact_max = options[:compact_max]
    end

    def render?
      genres.any?
    end

    private

    attr_reader :genres, :html, :tag_html, :pin_bottom, :compact_max

    def wrapper_classes
      ['flex flex-wrap gap-2', pin_bottom ? 'mt-auto pt-4' : nil, html[:class]].compact.join(' ')
    end

    # Below lg only the first compact_max pills stay, with a +N pill standing in for the rest.
    def collapsed?
      compact_max.present? && genres.size > compact_max
    end

    def overflow_count
      genres.size - compact_max
    end

    # max-lg:hidden rather than a bare hidden: the pill's base inline-flex would otherwise
    # win or lose on stylesheet order instead of breakpoint.
    def tag_html_for(genre)
      return tag_html unless collapsed? && genres.index(genre).to_i >= compact_max

      tag_html.merge(class: [tag_html[:class], 'max-lg:hidden'].compact.join(' '))
    end

    def sorted_genres(genres)
      adults, regular = genres.partition { |genre| Genre.adult_tag?(genre[:name], slug: genre[:slug]) }
      adults + regular
    end

    def tag_groups
      adults, regular = genres.partition { |genre| Genre.adult_tag?(genre[:name], slug: genre[:slug]) }
      groups = []
      groups << { type: :adult_cluster, genres: adults } if adults.any?
      regular.each { |genre| groups << { type: :single, genre: genre } }
      groups
    end

    def tag_variant_for(genre)
      Genre.tag_variant(name: genre[:name], slug: genre[:slug])
    end
  end
end
