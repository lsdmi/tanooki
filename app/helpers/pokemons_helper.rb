# frozen_string_literal: true

module PokemonsHelper
  def cooldown?(current_user, selected_opponent)
    (current_user.id == selected_opponent.id) ||
      (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago ||
      (selected_opponent.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago
  end

  def reason_for_cooldown(current_user, selected_opponent)
    return if current_user.id == selected_opponent.id

    opponent_fight = selected_opponent.battle_logs.maximum(:updated_at) || 1.year.ago
    user_fight = current_user.battle_logs.maximum(:updated_at) || 1.year.ago
    earliest_log = [opponent_fight, user_fight].max
    cooldown_message_for(earliest_log)
  end

  def dex_title(rate)
    case rate
    when -Float::INFINITY..20 then 'Початківець (Ранг E)'
    when 21..40 then 'Школяр (Ранг D)'
    when 41..60 then 'Тренер (Ранг C)'
    when 61..80 then 'Висхідна зірка (Ранг B)'
    when 81..90 then 'Майстер (Ранг A)'
    else 'Чемпіон (Ранг S)'
    end
  end

  private

  def cooldown_message_for(time)
    remaining_cooldown_seconds = 4.hours.to_i - (Time.now - time)
    remaining_cooldown_hours = (remaining_cooldown_seconds / 1.minute).floor
    "#{remaining_cooldown_hours} хв."
  end
end
