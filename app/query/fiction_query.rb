# frozen_string_literal: true

module FictionQuery
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
      .group(:fiction_id)
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
