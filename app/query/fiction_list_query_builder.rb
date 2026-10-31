# frozen_string_literal: true

# Builds filtered fiction list scopes from index/list params (genre, filters, ordering).
class FictionListQueryBuilder
  TOP_RATED_MIN_AVERAGE = 4.5
  DEFAULT_SORT = 'updated_desc'
  SORTS = %w[
    updated_desc
    updated_asc
    title_asc
    title_desc
    popular_desc
    popular_asc
    rating_desc
    rating_asc
  ].freeze

  FILTER_STEPS = %i[
    by_genre
    only_new_fictions
    longreads_only
    evening_only
    top_rated_only
    finished_only
    licensed_only
    matching_query
  ].freeze

  def initialize(relation = Fiction.all, params = {})
    @relation = relation
    @params = params.to_h.with_indifferent_access
  end

  def call
    scope = FILTER_STEPS.reduce(@relation) { |results, step| send(step, results) }
    FictionListSorter.apply(scope, @params['sort'])
                     .includes(:cover_attachment, :genres, :fiction_ratings)
  end

  def self.normalize_sort(value)
    key = value.to_s
    SORTS.include?(key) ? key : DEFAULT_SORT
  end

  def self.title_sort_sql(column = 'fictions.title')
    FictionListSorter.title_sort_sql(column)
  end

  private

  def by_genre(scope)
    return scope if @params['genre'].blank?

    # Filter via subquery so includes(:genres) still loads every genre, not only the matched one.
    scope.where(id: FictionGenre.where(genre_id: @params['genre']).select(:fiction_id))
  end

  def only_new_fictions(scope)
    return scope if @params['only_new'].blank?

    scope.where(fictions: { created_at: 30.days.ago.. })
  end

  def longreads_only(scope)
    return scope if @params['longreads'].blank?

    # Use a subquery to find fictions with many chapters
    long_fiction_ids = Fiction.joins(:chapters)
                              .merge(Chapter.released)
                              .group('fictions.id')
                              .having('COUNT(chapters.id) >= ?', 100)
                              .pluck(:id)

    scope.where(id: long_fiction_ids)
  end

  def evening_only(scope)
    return scope if @params['evening'].blank?

    # At most 10 released chapters (includes fictions with none: they are not in the "many" set).
    many_chapter_ids = Fiction.joins(:chapters)
                              .merge(Chapter.released)
                              .group('fictions.id')
                              .having('COUNT(chapters.id) > ?', 10)
                              .pluck(:id)

    many_chapter_ids.any? ? scope.where.not(id: many_chapter_ids) : scope
  end

  def top_rated_only(scope)
    return scope if @params['top_rated'].blank?

    top_ids = Fiction.joins(:fiction_ratings)
                     .group('fictions.id')
                     .having('AVG(fiction_ratings.rating) > ?', TOP_RATED_MIN_AVERAGE)
                     .pluck(:id)

    top_ids.any? ? scope.where(id: top_ids) : scope.none
  end

  def finished_only(scope)
    return scope if @params['finished'].blank?

    scope.finished
  end

  def matching_query(scope)
    query = @params['q'].to_s.strip
    return scope if query.length < 2

    like = "%#{ActiveRecord::Base.sanitize_sql_like(query)}%"
    scope.where(<<~SQL.squish, q: like)
      fictions.title LIKE :q
      OR fictions.alternative_title LIKE :q
      OR fictions.english_title LIKE :q
      OR fictions.author LIKE :q
    SQL
  end

  def licensed_only(scope)
    return scope if @params['licensed'].blank?

    scope.licensed
  end
end
