# frozen_string_literal: true

module Chapters
  # Formats chapter numbers and volume labels for display.
  module Formatting
    module_function

    def format_decimal(number)
      decimal_part = number.to_s.split('.').last.to_i
      decimal_part.zero? ? number.to_i : number
    end

    # A range bound reads as a whole chapter (4.1–57.2 → 4–57). A prologue below 1 stays as written,
    # so 0.5 does not become 0.
    def range_bound(number)
      return format_decimal(number) if number < 1

      number.to_i
    end

    def number_span(first, last)
      [first, last].map { |number| range_bound(number) }.uniq.join('–')
    end
  end
end
