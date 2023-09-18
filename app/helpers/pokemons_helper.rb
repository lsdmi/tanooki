# frozen_string_literal: true

module PokemonsHelper
  COOLDOWN_LESS_THAN_ONE_HOUR = 'Кулдаун: менше 1-ї години'.freeze
  COOLDOWN_ONE_HOUR = 'Кулдаун: близько 1-ї години'.freeze
  COOLDOWN_YOURSELF = 'На милість, не бийте самого себе!'.freeze

  def cooldown?(current_user, selected_opponent)
    (current_user.id == selected_opponent.id) ||
    (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago ||
    (selected_opponent.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago
  end

  def reason_for_cooldown(current_user, selected_opponent)
    return COOLDOWN_YOURSELF if current_user.id == selected_opponent.id

    (current_user.battle_logs.maximum(:updated_at) || 1.year.ago) > 4.hours.ago ? cooldown_message_for(current_user) : cooldown_message_for(selected_opponent)
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

  private

  def cooldown_message_for(user)
    remaining_cooldown_seconds = 4.hours.to_i - Time.now - user.battle_logs.maximum(:updated_at)
    remaining_cooldown_hours = (remaining_cooldown_seconds / 1.hour).floor

    case remaining_cooldown_hours
    when 0
      COOLDOWN_LESS_THAN_ONE_HOUR
    when 1
      COOLDOWN_ONE_HOUR
    when 2..5
      "Кулдаун: близько #{remaining_cooldown_hours}-х годин"
    end
  end
end
