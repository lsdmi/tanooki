# frozen_string_literal: true

module LibraryChapterCatalogHelper
  # viewer: pass current_user from views; nil = guest (only chapters already visible to everyone).
  def ordered_chapters(fiction, viewer: nil)
    chapters_scope_for_list(fiction, viewer).order(order_clause)
  end

  def ordered_chapters_desc(fiction, viewer: nil)
    chapters_scope_for_list(fiction, viewer).order(order_clause_desc)
  end

  def ordered_user_chapters_desc(fiction, user)
    base = fiction.chapters.order(order_clause_desc)
    return base if user.admin?

    base.joins(:scanlators).where(scanlators: { id: user.scanlators.ids }).distinct
  end

  def chapters_size(fiction, viewer: nil)
    unique_chapters(ordered_chapters(fiction, viewer:)).size
  end

  def fiction_has_listable_chapters?(fiction, viewer)
    chapters_scope_for_list(fiction, viewer).exists?
  end

  def duplicate_chapters(fiction)
    cache_key = build_duplicate_chapters_cache_key(fiction)
    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      find_duplicated_chapters(fiction)
    end
  rescue StandardError => e
    Rails.logger.error "Error in duplicate_chapters for fiction #{fiction.id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    fiction.chapters.none
  end

  private

  # Guests: only chapters already public. Team on this fiction: also chapters with future published_at they scanlate.
  def chapters_scope_for_list(fiction, viewer)
    return fiction.chapters if viewer&.admin?

    chapters_scope_by_visibility(fiction, viewer)
  end

  def chapters_scope_by_visibility(fiction, viewer)
    now = Time.current
    released_sql = visible_to_everyone_sql_fragment
    return fiction.chapters.where(released_sql, now) if guest_or_no_team_overlap?(fiction, viewer)

    fiction.chapters.where(sql_visible_now_or_future_for_team(released_sql), now, now, viewer.scanlators.ids)
  end

  def guest_or_no_team_overlap?(fiction, viewer)
    viewer.nil? || !viewer.scanlators.ids.intersect?(fiction.scanlators.ids)
  end

  def visible_to_everyone_sql_fragment
    '(chapters.published_at IS NULL OR chapters.published_at <= ?)'
  end

  def sql_visible_now_or_future_for_team(visible_to_all_sql)
    "#{visible_to_all_sql} OR (chapters.published_at > ? AND EXISTS (" \
      'SELECT 1 FROM chapter_scanlators cs WHERE cs.chapter_id = chapters.id AND cs.scanlator_id IN (?)))'
  end

  def build_duplicate_chapters_cache_key(fiction)
    max_updated_at = fiction.chapters.maximum(:updated_at) || fiction.updated_at
    "duplicate_chapters/#{fiction.id}/#{max_updated_at}"
  end

  def find_duplicated_chapters(fiction)
    chapter_groups = fiction.chapters.includes(:scanlators).group_by(&:number)
    duplicated_numbers = find_duplicated_chapter_numbers(chapter_groups)
    fiction.chapters.where(number: duplicated_numbers)
  end

  def find_duplicated_chapter_numbers(chapter_groups)
    chapter_groups.filter_map do |number, chapters|
      scanlator_combinations = extract_scanlator_combinations(chapters)
      number if scanlator_combinations.size > 1
    end
  end

  def extract_scanlator_combinations(chapters)
    chapters.map { |chapter| chapter.scanlators.pluck(:id).sort }.uniq
  end

  def order_clause
    Arel.sql(
      'CASE WHEN volume_number IS NULL OR volume_number = 0 ' \
      "THEN number ELSE volume_number END, number, #{Chapter::PUBLIC_TIME_SQL}"
    )
  end

  def order_clause_desc
    Arel.sql("COALESCE(volume_number, 0) DESC, number DESC, #{Chapter::PUBLIC_TIME_SQL} DESC")
  end
end
