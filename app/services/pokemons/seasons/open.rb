# frozen_string_literal: true

module Pokemons
  module Seasons
    # Opens the next Pokémon season. The first one starts today and ends with the current two-month block; later ones
    # start the day after the previous +ends_on+ and cover that full block.
    class Open
      def self.next!(at: Time.current)
        new(at:).call
      end

      def initialize(at: Time.current)
        @at = at
      end

      def call
        raise 'a season is already open' if PokemonSeason.current

        previous = PokemonSeason.order(ends_on: :desc).first
        starts_on, ends_on = bounds(previous)
        PokemonSeason.create!(number: next_number, starts_on:, ends_on:)
      end

      private

      attr_reader :at

      def next_number
        (PokemonSeason.maximum(:number) || 0) + 1
      end

      def bounds(previous)
        return [at.to_date, Calendar.period_covering(at.to_date).last] unless previous

        Calendar.period_after(previous.ends_on)
      end
    end
  end
end
