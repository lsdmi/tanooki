# frozen_string_literal: true

class FictionListQueryBuilder
  def initialize(relation = Fiction.all, params = {})
    @relation = relation
    @params = params.to_h.with_indifferent_access
  end

  def call
    results = @relation
    results = by_genre(results)
    results = only_new_fictions(results)
    results = longreads_only(results)
    results = finished_only(results)
    results = with_recent_chapters_subquery(results)
    results.includes(:cover_attachment, :genres)
  end

  private

  def by_genre(scope)
    return scope unless @params['genre'].present?

    scope.joins(:genres).where(genres: { id: @params['genre'] })
  end

  def only_new_fictions(scope)
    return scope unless @params['only_new'].present?

    scope.where('fictions.created_at >= ?', 30.days.ago)
  end

  def longreads_only(scope)
    return scope unless @params['longreads'].present?

    # Use a subquery to find fictions with many chapters
    long_fiction_ids = Fiction.joins(:chapters)
                              .group('fictions.id')
                              .having('COUNT(chapters.id) >= ?', 100)
                              .pluck(:id)

    scope.where(id: long_fiction_ids)
  end

  def finished_only(scope)
    return scope unless @params['finished'].present?

    scope.where(status: 'Завершено')
  end

  def with_recent_chapters_subquery(scope)
    max_chapters = Chapter.select('fiction_id, MAX(created_at) AS max_created_at').group(:fiction_id)

    scope.joins("LEFT JOIN (#{max_chapters.to_sql}) AS chapters_max ON chapters_max.fiction_id = fictions.id")
         .order(Arel.sql('COALESCE(chapters_max.max_created_at, fictions.created_at) DESC'))
  end
end
