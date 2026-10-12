# frozen_string_literal: true

module Pokemons
  module Seasons
    # Two-month ladder blocks: Jan–Feb, Mar–Apr, May–Jun, Jul–Aug, Sep–Oct, Nov–Dec (Europe/Kiev dates).
    module Calendar
      module_function

      # Inclusive [starts_on, ends_on] for the block that contains +date+.
      def period_covering(date)
        start_month = (((date.month - 1) / 2) * 2) + 1
        starts_on = Date.new(date.year, start_month, 1)
        [starts_on, (starts_on >> 2) - 1]
      end

      # The block that begins on the day after +ends_on+.
      def period_after(ends_on)
        period_covering(ends_on + 1.day)
      end
    end
  end
end
