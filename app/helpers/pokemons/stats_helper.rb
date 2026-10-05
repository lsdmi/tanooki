# frozen_string_literal: true

module Pokemons
  # Type badge colors, stat and battle-experience labels for Pokémon detail UI.
  module StatsHelper
    TYPE_COLORS = {
      'Звичайний' => 'token-raw bg-gray-400 dark:bg-gray-600',
      'Вогняний' => 'bg-red-500 dark:bg-red-700',
      'Водяний' => 'bg-blue-500 dark:bg-blue-700',
      'Електричний' => 'bg-yellow-500 dark:bg-yellow-600',
      "Трав'яний" => 'bg-green-500 dark:bg-green-700',
      'Льодовий' => 'bg-blue-300 dark:bg-blue-500',
      'Бойовий' => 'bg-red-700 dark:bg-red-900',
      'Отруйний' => 'bg-purple-500 dark:bg-purple-700',
      'Ґрунтовий' => 'bg-yellow-700 dark:bg-yellow-900',
      'Повітряний' => 'bg-blue-400 dark:bg-blue-600',
      'Психічний' => 'bg-purple-400 dark:bg-purple-600',
      'Комашиний' => 'bg-yellow-600 dark:bg-yellow-800',
      'Скельний' => 'token-raw bg-gray-600 dark:bg-gray-800',
      'Примарний' => 'bg-purple-300 dark:bg-purple-500',
      'Драконячий' => 'bg-indigo-600 dark:bg-indigo-800'
    }.freeze

    TYPE_BADGE = 'inline-flex items-center rounded-full px-2 py-0.5 text-xs/4 font-medium text-white'

    def pokemon_type_badge(type)
      tag.span(type, class: "#{TYPE_BADGE} #{TYPE_COLORS[type]}")
    end

    # The species' standing as a word (StatTiers): +kind+ is :might, :stamina or :strike.
    def stat_tier_label(pokemon, kind)
      t("pokemons.stat_tiers.#{kind}")[Pokemons::StatTiers.for(pokemon).public_send(kind) - 1]
    end

    def experience_to_sentence(rate)
      case rate
      when 0 then 'Відсутній'
      when 1..20 then 'Початківець'
      when 21..50 then 'Вояк'
      when 51..90 then 'Ветеран'
      else 'Незборний'
      end
    end
  end
end
