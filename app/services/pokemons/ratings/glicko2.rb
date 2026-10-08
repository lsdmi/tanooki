# frozen_string_literal: true

module Pokemons
  module Ratings
    # Glicko-2 (Glickman, "Example of the Glicko-2 system", 2012). The game rates each battle on its own, and a
    # trainer's deviation grows with the time since their last rated battle (PERIOD per rating period, fractional), so
    # a returning trainer's rating moves fast again while a burst of battles in one day does not inflate it.
    module Glicko2
      SCALE = 173.7178
      PERIOD = 1.day
      # Constrains volatility changes; 0.3–1.2 in the paper, low for a game with upsets.
      TAU = 0.5
      CONVERGENCE = 0.000001

      Rating = Data.define(:rating, :deviation, :volatility) do
        # What the leaderboard ranks by: a new or returning trainer earns a place with a few battles.
        def floor = rating - (2 * deviation)

        # The deviation after +periods+ without a rated battle, capped at a newcomer's.
        def idle(periods)
          deviation = Math.sqrt((self.deviation**2) + (periods * ((volatility * SCALE)**2)))
          with(deviation: [deviation, NEW.deviation].min)
        end
      end

      NEW = Rating.new(rating: 1500.0, deviation: 350.0, volatility: 0.06)

      # +player+'s rating after +games+, [opponent, score] pairs (score 1 for a win, 0 for a loss; each opponent as they
      # stand, idle growth applied). +periods+ is the player's time since their last rated battle; the paper's single
      # rating period is 1.
      def self.rate(player, games, periods: 1) = Update.new(player, games).call(periods)
    end
  end
end
