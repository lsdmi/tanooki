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

  def cloud_link_size(size)
    case ratio(size)
    when 0.7..Float::INFINITY
      'text-3xl sm:text-4xl md:text-5xl lg:text-6xl'
    when 0.6..0.7
      'text-2xl sm:text-3xl md:text-4xl lg:text-5xl'
    when 0.5..0.6
      'text-xl sm:text-2xl md:text-3xl lg:text-4xl'
    when 0.4..0.5
      'text-lg sm:text-xl md:text-2xl lg:text-3xl'
    when 0.3..0.4
      'text-base sm:text-lg md:text-xl lg:text-2xl'
    when 0.2..0.3
      'text-sm sm:text-base md:text-lg lg:text-xl'
    else
      'text-xs sm:text-sm md:text-base lg:text-lg'
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

  def genres_size
    return 0 if @genres.nil?

    @genres.size.to_f
  end

  def ratio(size)
    size / genres_size
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

  def random_tag_color
    [
      'hover:bg-orange-200',
      'hover:bg-emerald-200',
      'hover:bg-sky-200',
      'hover:bg-indigo-200',
      'hover:bg-purple-200',
      'hover:bg-pink-200'
    ].sample
  end
end
