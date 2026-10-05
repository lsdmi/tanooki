# frozen_string_literal: true

module Pokemons
  # Type badge colors, stat and battle-experience labels for Pokémon detail UI.
  module StatsHelper
    TYPE_COLORS = {
      'normal' => 'token-raw bg-gray-400 dark:bg-gray-600',
      'fire' => 'bg-red-500 dark:bg-red-700',
      'water' => 'bg-blue-500 dark:bg-blue-700',
      'electric' => 'bg-yellow-500 dark:bg-yellow-600',
      'grass' => 'bg-green-500 dark:bg-green-700',
      'ice' => 'bg-blue-300 dark:bg-blue-500',
      'fighting' => 'bg-red-700 dark:bg-red-900',
      'poison' => 'bg-purple-500 dark:bg-purple-700',
      'ground' => 'bg-yellow-700 dark:bg-yellow-900',
      'flying' => 'bg-blue-400 dark:bg-blue-600',
      'psychic' => 'bg-purple-400 dark:bg-purple-600',
      'bug' => 'bg-yellow-600 dark:bg-yellow-800',
      'rock' => 'token-raw bg-gray-600 dark:bg-gray-800',
      'ghost' => 'bg-purple-300 dark:bg-purple-500',
      'dragon' => 'bg-indigo-600 dark:bg-indigo-800'
    }.freeze

    TYPE_BADGE = 'inline-flex items-center rounded-full px-2 py-0.5 text-xs/4 font-medium text-white'

    def pokemon_type_badge(type)
      tag.span(type.label, class: "#{TYPE_BADGE} #{TYPE_COLORS[type.key]}")
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
