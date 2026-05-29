# frozen_string_literal: true

module Chapters
  # Formats chapter numbers and volume labels for display.
  module Formatting
    module_function

    def format_decimal(number)
      decimal_part = number.to_s.split('.').last.to_i
      decimal_part.zero? ? number.to_i : number
    end
  end
end
