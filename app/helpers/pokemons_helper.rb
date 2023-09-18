# frozen_string_literal: true

module PokemonsHelper
  def cooldown?(current_user, selected_opponent)
    (current_user.id == selected_opponent.id) ||
    (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago ||
    (selected_opponent.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago
  end

  def dex_title(rate)
    case rate
    when -Float::INFINITY..20
      'Початківець (Ранг E)'
    when 21..40
      'Школяр (Ранг D)'
    when 41..60
      'Тренер (Ранг C)'
    when 61..80
      'Висхідна зірка (Ранг B)'
    when 81..90
      'Майстер (Ранг A)'
    else
      'Чемпіон (Ранг S)'
    end
  end
end
