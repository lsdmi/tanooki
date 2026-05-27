# frozen_string_literal: true

# Dashboard view helpers for Pokemon stats.
module DashboardHelper
  TYPE_COLORS = {
    'Звичайний' => 'bg-gray-400 dark:bg-gray-600',
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
    'Скельний' => 'bg-gray-600 dark:bg-gray-800',
    'Примарний' => 'bg-purple-300 dark:bg-purple-500',
    'Драконячий' => 'bg-indigo-600 dark:bg-indigo-800'
  }.freeze

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
