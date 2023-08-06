# frozen_string_literal: true

module FictionQuery
  def dashboard_fiction_list
    fiction_all_query
      .where(chapters: { user_id: current_user.id })
      .or(UserFiction.where(user_id: current_user.id))
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
      .distinct
  end

  def fiction_all_query
    Fiction.left_joins(:chapters).joins(:user_fictions)
  end

  def fiction_all_ordered_by_latest_chapter
    fiction_all_query
      .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
      .group('fictions.id, fictions.created_at')
      .order(Arel.sql('COALESCE(MAX(chapters.created_at), fictions.created_at) DESC'))
  end

  def filtered_fiction_with_max_created_at_query
    Fiction.joins(:chapters).includes([{ cover_attachment: :blob }, :genres])
           .where(genres: { id: params[:genre_id] })
           .select('fictions.*, MAX(chapters.created_at) AS max_created_at')
           .group('fictions.id, active_storage_attachments.id')
           .order('max_created_at DESC')
  end
end
