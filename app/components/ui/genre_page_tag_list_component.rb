# frozen_string_literal: true

module Ui
  # Row of dark genre pills on featured genre-page cards.
  class GenrePageTagListComponent < ViewComponent::Base
    def initialize(genres:, **options)
      super()
      @genres = Array(genres).compact_blank
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
  end
end
