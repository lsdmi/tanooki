# frozen_string_literal: true

module Pokemons
  module Ratings
    module Glicko2
      # Step 5 of the paper: the new volatility σ′, the root of f found with the Illinois algorithm.
      class Volatility
        def initialize(phi:, sigma:, variance:, delta:)
          @a = Math.log(sigma**2)
          @base = (phi**2) + variance
          @delta_squared = delta**2
        end

        def call
          @lower = @a
          @upper = upper_bound
          @f_lower = f(@lower)
          @f_upper = f(@upper)
          narrow while (@upper - @lower).abs > CONVERGENCE
          Math.exp(@lower / 2)
        end

        private

        def narrow
          step = @lower + ((@lower - @upper) * @f_lower / (@f_upper - @f_lower))
          f_step = f(step)
          if f_step * @f_upper <= 0
            @lower = @upper
            @f_lower = @f_upper
          else
            @f_lower /= 2
          end
          @upper = step
          @f_upper = f_step
        end

        def upper_bound
          return Math.log(@delta_squared - @base) if @delta_squared > @base

          k = 1
          k += 1 while f(@a - (k * TAU)).negative?
          @a - (k * TAU)
        end

        def f(guess)
          ex = Math.exp(guess)
          ((ex * (@delta_squared - @base - ex)) / (2 * ((@base + ex)**2))) - ((guess - @a) / (TAU**2))
        end
      end
    end
  end
end
