# frozen_string_literal: true

module PokemonsHelper
  def dex_title(index)
    case index
    when 0
      'Чемпіон'
    when 1..4
      'Елітна четвірка'
    when 5..Float::INFINITY
      'Тренер'
    end
  end
end
