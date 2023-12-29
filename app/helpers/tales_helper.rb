

# frozen_string_literal: true

module TalesHelper
  def header_picker(size)
    case size
    when 75..Float::INFINITY
      'h-80'
    when 50..74
      'h-72'
    when 25..49
      'h-64'
    else
      'h-60'
    end
  end
end
