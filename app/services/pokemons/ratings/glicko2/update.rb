# frozen_string_literal: true

module Pokemons
  module Ratings
    module Glicko2
      # Steps 2–8 of the paper for one player over one rating period, on the Glicko-2 scale (μ, φ).
      class Update
        def initialize(player, games)
          @mu, @phi = scale(player)
          @sigma = player.volatility
          @terms = games.map { |opponent, score| term(*scale(opponent), score) }
        end

        def call(periods)
          sigma = Volatility.new(phi: @phi, sigma: @sigma, variance:, delta: variance * improvement).call
          phi = new_phi(sigma, periods)
          Rating.new(rating: unscale(@mu + ((phi**2) * improvement)),
                     deviation: [SCALE * phi, NEW.deviation].min, volatility: sigma)
        end

        private

        def scale(rating) = [(rating.rating - NEW.rating) / SCALE, rating.deviation / SCALE]

        def unscale(scaled) = NEW.rating + (SCALE * scaled)

        # Steps 6–7: the pre-period deviation grown by +periods+, then narrowed by the games.
        def new_phi(sigma, periods) = 1 / Math.sqrt((1 / ((@phi**2) + (periods * (sigma**2)))) + (1 / variance))

        # [g(φⱼ), E, score] for one game against an opponent at μⱼ, φⱼ.
        def term(opponent_mu, opponent_phi, score)
          g = 1 / Math.sqrt(1 + (3 * (opponent_phi**2) / (Math::PI**2)))
          [g, 1 / (1 + Math.exp(-g * (@mu - opponent_mu))), score]
        end

        def variance
          @variance ||= 1 / @terms.sum { |g, expected, _| (g**2) * expected * (1 - expected) }
        end

        def improvement
          @improvement ||= @terms.sum { |g, expected, score| g * (score - expected) }
        end
      end
    end
  end
end
