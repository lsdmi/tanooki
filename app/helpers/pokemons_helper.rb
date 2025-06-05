# frozen_string_literal: true

module PokemonsHelper
  def cooldown?(current_user)
    (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago
  end

  def training_cooldown?(user)
    user.pokemon_last_training > 4.hours.ago
  end

  def training_cooldown_reason(user)
    cooldown_message_for(user.pokemon_last_training)
  end

  def reason_for_cooldown(current_user)
    user_fight = current_user.battle_logs.maximum(:updated_at) || 1.year.ago
    cooldown_message_for(user_fight)
  end

  def dex_title(rate)
    case rate
    when -Float::INFINITY..35 then 'Початківець'
    when 36..55 then 'Школяр'
    when 56..75 then 'Тренер'
    when 76..90 then 'Висхідна зірка'
    when 91..98 then 'Майстер'
    else 'Чемпіон'
    end
  end

  private

  def cooldown_message_for(time)
    remaining_cooldown_seconds = 4.hours.to_i - (Time.now - time)
    remaining_cooldown_hours = (remaining_cooldown_seconds / 1.minute).floor
    remaining_cooldown_hours = 240 if remaining_cooldown_hours.negative?

    "#{remaining_cooldown_hours} хв"
  end
end
