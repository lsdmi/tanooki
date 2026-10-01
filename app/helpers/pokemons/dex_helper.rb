# frozen_string_literal: true

module Pokemons
  # Dex leaderboard rank labels and training/battle cooldown copy for the dex UI.
  module DexHelper
    def training_cooldown?(user)
      user.pokemon_training_on_cooldown?
    end

    def training_cooldown_reason(user)
      cooldown_message_for(user.pokemon_last_training, Balance::TRAINING_COOLDOWN)
    end

    def reason_for_cooldown(current_user)
      cooldown_message_for(current_user.last_battle_at || 1.year.ago, Balance::BATTLE_COOLDOWN)
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

    def cooldown_message_for(time, cooldown)
      remaining_minutes = ((cooldown.to_i - (Time.current - time)) / 1.minute).floor
      remaining_minutes = cooldown.in_minutes.to_i if remaining_minutes.negative?

      "#{remaining_minutes} хв"
    end
  end
end
