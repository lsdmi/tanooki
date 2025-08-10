# frozen_string_literal: true

module FictionQuery
  def dashboard_fiction_list
    fiction_all_query
      .where('chapters.user_id = ? OR users.id = ?', Current.user.id, current_usCurrent.userer.id)
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
      .distinct
  end

  def fiction_all_query
    Fiction.left_joins(:chapters).joins(:users).includes(:cover_attachment)
  end

  def fiction_all_ordered_by_latest_chapter
    fiction_all_query
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
  end
end
