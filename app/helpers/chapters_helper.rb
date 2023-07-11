# frozen_string_literal: true

module ChaptersHelper
  def check_decimal(number)
    decimal_part = number.to_s.split('.').last.to_i
    decimal_part.zero? ? number.to_i : number
  end
end
