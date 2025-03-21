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
    announced: 'text-[#D4AF37]', # Metallic Gold
    dropped: 'text-[#8B0000]',   # Dark Red
    ongoing: 'text-[#4682B4]',   # Steel Blue
    finished: 'text-[#2E8B57]'   # Sea Green
  }.freeze

  def format_view_count(count)
    if count >= 1000
      formatted = (count / 1000.0).round(1)
      "#{formatted}т"
    else
      count.to_s
    end
  end
end
