# frozen_string_literal: true

module DashboardHelper
  TYPE_COLORS = {
    'Звичайний' => 'bg-gray-400',
    'Вогняний' => 'bg-red-500',
    'Водяний' => 'bg-blue-500',
    'Електричний' => 'bg-yellow-500',
    "Трав'яний" => 'bg-green-500',
    'Льодовий' => 'bg-blue-300',
    'Бойовий' => 'bg-red-700',
    'Отруйний' => 'bg-purple-500',
    'Ґрунтовий' => 'bg-yellow-700',
    'Повітряний' => 'bg-blue-400',
    'Психічний' => 'bg-purple-400',
    'Комашиний' => 'bg-yellow-600',
    'Скельний' => 'bg-gray-600',
    'Примарний' => 'bg-purple-300',
    'Драконячий' => 'bg-indigo-600'
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
