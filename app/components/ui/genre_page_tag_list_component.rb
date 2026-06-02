# frozen_string_literal: true

module Ui
  # Row of genre pills on featured genre-page cards (outline in light mode, slate on dark panel).
  class GenrePageTagListComponent < ViewComponent::Base
    def initialize(genres:, **options)
      super()
      @genres = sorted_genres(Array(genres).compact_blank)
      @html = options.fetch(:html, {})
    end

    def render?
      genres.any?
    end

    private

    attr_reader :genres, :html

    def wrapper_classes
      ['mt-auto flex flex-wrap gap-2 pt-4', html[:class]].compact.join(' ')
    end

    def sorted_genres(genres)
      adults, regular = genres.partition { |genre| Genre.adult_tag?(genre[:name], slug: genre[:slug]) }
      adults + regular
    end

    def tag_variant_for(genre)
      Genre.tag_variant(name: genre[:name], slug: genre[:slug])
    end
  end
end
