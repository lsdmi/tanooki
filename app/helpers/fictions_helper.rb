# frozen_string_literal: true

module FictionsHelper
  GENRE_BADGES = {
    'BL' => 'bl',
    'GL' => 'gl',
    'Бойовик' => 'action',
    'Вуся' => 'wuxia',
    'Гарем' => 'harem',
    'Детектив' => 'detective',
    'Драма' => 'drama',
    'Жахи' => 'horror',
    'Ісекай' => 'isekai',
    'Історичне' => 'history',
    'Комедія' => 'comedy',
    'ЛГБТ' => 'lgbt',
    'Містика' => 'mystic',
    'Омегаверс' => 'omegaverse',
    'Повсякденність' => 'lifeslice',
    'Пригоди' => 'adventure',
    'Романтика' => 'romance'
  }.freeze

  STATUS_COLORS = {
    announced: 'text-amber-700',
    dropped: 'text-red-700',
    ongoing: 'text-sky-700',
    finished: 'text-emerald-700'
  }.freeze

  def fiction_author(fiction)
    if fiction.scanlators.any?
      scanlator_links = fiction.scanlators.map do |scanlator|
        link_to scanlator.title, scanlator_path(scanlator), class: 'font-extrabold tracking-tight text-emerald-900 text-emerald-700 hover:underline hover:text-emerald-600 inline-block'
      end.join(', ').html_safe

      "Перекладач: #{content_tag(:strong, scanlator_links)}".html_safe
    else
      "Оригінальна робота #{content_tag(:strong, fiction.author)}".html_safe
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
    when 0.75..Float::INFINITY
      'text-3xl sm:text-4xl md:text-5xl lg:text-6xl'
    when 0.5..0.75
      'text-xl sm:text-2xl md:text-3xl lg:text-4xl'
    when 0.25..0.5
      'text-base sm:text-lg md:text-xl lg:text-2xl'
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
