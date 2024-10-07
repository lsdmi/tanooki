# frozen_string_literal: true

module FictionsHelper
  GENRE_BADGES = {
    'BL' => 'bl', 'GL' => 'gl', 'Бойовик' => 'action', 'Вуся' => 'wuxia', 'Гарем' => 'harem', 'Детектив' => 'detective',
    'Драма' => 'drama', 'Жахи' => 'horror', 'Ісекай' => 'isekai', 'Історичне' => 'history', 'Комедія' => 'comedy',
    'ЛГБТ' => 'lgbt', 'Містика' => 'mystic', 'Повсякденність' => 'lifeslice', 'Пригоди' => 'adventure',
    'Психологія' => 'psychological', 'Романтика' => 'romance', 'Спорт' => 'sport', 'Сюаньхвань' => 'xuanhuan',
    'Сянься' => 'xianxia', 'Трагедія' => 'tragedy', 'Трилер' => 'thriller', 'Фантастика' => 'scifi',
    'Фентезі' => 'fantasy', 'Школа' => 'school'
  }.freeze

  STATUS_COLORS = {
    announced: 'text-[#FFFF00]', # Bright Yellow
    dropped: 'text-[#FF1493]',   # Hot Pink (for a more neon "red")
    ongoing: 'text-[#00BFFF]',   # Electric Blue
    finished: 'text-[#39FF14]'   # Neon Green
  }.freeze

  def fiction_author(fiction)
    if fiction.scanlators.any?
      scanlator_links = fiction.scanlators.map do |scanlator|
        link_to scanlator.title, scanlator_path(scanlator), class: scanlator_link_classes
      end.join(', ').html_safe

      "Перекладач: #{content_tag(:strong, scanlator_links)}".html_safe
    else
      "Оригінальна робота #{content_tag(:strong, fiction.author)}".html_safe
    end
  end

  def cloud_link_size(size)
    case ratio(size)
    when 0.85..Float::INFINITY
      'text-3xl sm:text-4xl md:text-5xl lg:text-6xl'
    when 0.6..0.85
      'text-xl sm:text-2xl md:text-3xl lg:text-4xl'
    when 0.35..0.6
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
    return 0 if @index_presenter.genres.nil?

    @index_presenter.genres.size.to_f
  end

  def ratio(size)
    size / genres_size
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

  private

  def scanlator_link_classes
    'font-extrabold tracking-tight text-emerald-900 ' \
      'text-emerald-700 hover:underline hover:text-emerald-600 inline-block'
  end
end
