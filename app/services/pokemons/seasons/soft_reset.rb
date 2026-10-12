# frozen_string_literal: true

module Pokemons
  module Seasons
    # Pulls a Glicko-2 rating halfway back to 1500 and raises the deviation to at least RESET_DEVIATION, so a strong
    # trainer keeps a lead into the new season but has to confirm it. Volatility is left alone.
    module SoftReset
      RESET_DEVIATION = 150.0

      module_function

      def apply(rating)
        Ratings::Glicko2::Rating.new(
          rating: Ratings::Glicko2::NEW.rating + ((rating.rating - Ratings::Glicko2::NEW.rating) / 2.0),
          deviation: [rating.deviation, RESET_DEVIATION].max,
          volatility: rating.volatility
        )
      end
    end
  end
end
