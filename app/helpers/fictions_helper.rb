# frozen_string_literal: true

module FictionsHelper
  def fiction_author(fiction)
    if fiction.translator.present?
      sanitize("Перекладач: <strong>#{fiction.translator}</strong>")
    else
      sanitize("Оригінальна робота <strong>#{fiction.author}</strong>")
    end
  end

  def chapter_item_theme(color)
    case color
    when :black
      black_chapter_theme
    when :gray
      gray_chapter_theme
    else
      green_chapter_theme
    end
  end

  def column_selector(size)
    case size
    when 5
      'col-span-5'
    when 4
      'col-span-4'
    when 3
      'col-span-3'
    when 2
      'col-span-2'
    end
  end

  def black_chapter_theme
    { icon: 'text-gray-500', text: 'text-gray-500', title: 'text-gray-900', title_hover: 'hover:text-gray-600' }
  end

  def gray_chapter_theme
    { icon: 'text-gray-400', text: 'text-gray-400', title: 'text-gray-500', title_hover: 'hover:text-gray-800' }
  end

  def green_chapter_theme
    { icon: 'text-emerald-700', text: 'text-emerald-700', title: 'text-emerald-900',
      title_hover: 'hover:text-emerald-600' }
  end
end
