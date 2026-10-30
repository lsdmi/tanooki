# frozen_string_literal: true

# Applies catalog sort keys to a fiction relation (title, updates, popularity, rating).
module FictionListSorter
  module_function

  # Latin letters fold onto Ukrainian peers so "Re: …" sorts with "Р", not before "А".
  TITLE_SORT_LATIN = {
    'A' => 'А', 'B' => 'Б', 'C' => 'С', 'D' => 'Д', 'E' => 'Е', 'F' => 'Ф',
    'G' => 'Г', 'H' => 'Х', 'I' => 'І', 'J' => 'Й', 'K' => 'К', 'L' => 'Л',
    'M' => 'М', 'N' => 'Н', 'O' => 'О', 'P' => 'П', 'Q' => 'К', 'R' => 'Р',
    'S' => 'С', 'T' => 'Т', 'U' => 'У', 'V' => 'В', 'W' => 'В', 'X' => 'Х',
    'Y' => 'И', 'Z' => 'З'
  }.freeze

  TITLE_SORT_SQL = TITLE_SORT_LATIN.reduce('UPPER(fictions.title)') do |expr, (latin, cyrillic)|
    "REPLACE(#{expr}, '#{latin}', '#{cyrillic}')"
  end.freeze

  ORDERERS = {
    'title' => :with_title_order,
    'updated' => :with_last_chapter_order,
    'popular' => :with_popularity_order,
    'rating' => :with_rating_order
  }.freeze

  def apply(scope, sort_key)
    key = FictionListQueryBuilder.normalize_sort(sort_key)
    direction = key.end_with?('_asc') ? 'ASC' : 'DESC'
    kind = key.sub(/_(?:asc|desc)\z/, '')
    public_send(ORDERERS.fetch(kind), scope, direction)
  end

  def title_sort_sql(_column = 'fictions.title')
    TITLE_SORT_SQL
  end

  def with_title_order(scope, direction)
    dir = direction.to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    scope.order(Arel.sql("#{TITLE_SORT_SQL} #{dir}"), 'fictions.id ASC')
  end

  def with_last_chapter_order(scope, direction)
    dir = direction.to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    max_chapters = Chapter.released
                          .select('fiction_id, MAX(COALESCE(published_at, created_at)) AS max_created_at')
                          .group(:fiction_id)

    scope.joins("LEFT JOIN (#{max_chapters.to_sql}) AS chapters_max ON chapters_max.fiction_id = fictions.id")
         .order(Arel.sql("COALESCE(chapters_max.max_created_at, fictions.created_at) #{dir}"))
         .order('fictions.id ASC')
  end

  def with_popularity_order(scope, direction)
    dir = direction.to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    subscriptions = ReadingProgress.select('fiction_id, COUNT(*) AS subscription_count').group(:fiction_id)

    scope.joins("LEFT JOIN (#{subscriptions.to_sql}) AS fiction_subs ON fiction_subs.fiction_id = fictions.id")
         .order(Arel.sql("COALESCE(fiction_subs.subscription_count, 0) #{dir}"))
         .order('fictions.id ASC')
  end

  def with_rating_order(scope, direction)
    dir = direction.to_s.downcase == 'asc' ? 'ASC' : 'DESC'
    ratings = FictionRating.select('fiction_id, AVG(rating) AS avg_rating').group(:fiction_id)
    subscriptions = ReadingProgress.select('fiction_id, COUNT(*) AS subscription_count').group(:fiction_id)

    scope.joins("LEFT JOIN (#{ratings.to_sql}) AS fiction_avgs ON fiction_avgs.fiction_id = fictions.id")
         .joins("LEFT JOIN (#{subscriptions.to_sql}) AS fiction_subs ON fiction_subs.fiction_id = fictions.id")
         .order(Arel.sql("COALESCE(fiction_avgs.avg_rating, 0) #{dir}"))
         .order(Arel.sql('COALESCE(fiction_subs.subscription_count, 0) DESC'))
         .order('fictions.id ASC')
  end
end
