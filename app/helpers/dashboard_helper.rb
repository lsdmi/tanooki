# frozen_string_literal: true

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

  def delete_icon
    content_tag(:div, class: delete_icon_container_classes) do
      content_tag(:svg, delete_icon_svg_options) do
        tag(:path, delete_icon_path_options)
      end
    end
  end

  private

  def delete_icon_container_classes
    'group flex items-center justify-center w-9 h-9 rounded-xl ' \
      'bg-stone-100 hover:bg-red-100 transition-all'
  end

  def delete_icon_svg_options
    {
      class: 'w-5 h-5 text-red-500 group-hover:text-red-700 transition-all',
      aria: { hidden: true },
      xmlns: 'http://www.w3.org/2000/svg',
      width: 24,
      height: 24,
      fill: 'none',
      viewBox: '0 0 24 24',
      stroke: 'currentColor'
    }
  end

  def delete_icon_path_options
    {
      stroke_linecap: 'round',
      stroke_linejoin: 'round',
      stroke_width: '2',
      d: delete_icon_path_d
    }
  end

  def delete_icon_path_d
    'M8.586 2.586A2 2 0 0 1 10 2h4a2 2 0 0 1 2 2v2h3a1 1 0 1 1 0 2v12a2 2 0 0 1-2 ' \
      '2H7a2 2 0 0 1-2-2V8a1 1 0 0 1 0-2h3V4a2 2 0 0 1 .586-1.414ZM10 6h4V4h-4v2Zm1 ' \
      '4a1 1 0 1 0-2 0v8a1 1 0 1 0 2 0v-8Zm4 0a1 1 0 1 0-2 0v8a1 1 0 1 0 2 0v-8Z'
  end
end
