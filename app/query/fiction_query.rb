# frozen_string_literal: true

module FictionQuery
  def dashboard_fiction_list
    fiction_all_query
      .where(chapters: { user_id: current_user.id })
      .or(Fiction.where(user_id: current_user.id))
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
      .distinct
  end

  def fiction_all_query
    Fiction.left_joins(:chapters)
  end

  def fiction_all_ordered_by_latest_chapter
    fiction_all_query
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
  end

  def fiction_base_query
    Fiction.joins(:chapters).includes([{ cover_attachment: :blob }, :genres])
  end

  def fiction_exclusions_query
    fiction_base_query.excluding(@popular_fictions, @most_reads, @latest_updates, @hot_updates)
  end

  def fiction_exclusions_query_mobile
    fiction_base_query
      .excluding(@popular_fictions.limit(4), @most_reads.limit(4), @latest_updates.limit(4), @hot_updates.limit(4))
  end

  def fiction_with_max_created_at_query
    fiction_base_query
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id')
      .order('max_created_at DESC')
  end

  def fiction_with_total_views_query
    fiction_base_query
      .select('fictions.*, SUM(chapters.views) AS total_views')
      .group('fictions.id')
      .order('total_views DESC')
  end

  def fiction_with_recent_hot_updates_query
    fiction_base_query
      .where('chapters.created_at >= ?', 7.days.ago)
      .select('fictions.*, SUM(chapters.views) AS total_views')
      .group('fictions.id')
      .order('total_views DESC')
  end
end
