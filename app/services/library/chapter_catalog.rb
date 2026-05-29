# frozen_string_literal: true

module Library
  # Visible, ordered fiction chapter lists for library views and services.
  module ChapterCatalog
    module_function

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
      ChapterNavigation.unique_chapters(ordered_chapters(fiction, viewer:)).size
    end

    def fiction_has_listable_chapters?(fiction, viewer)
      chapters_scope_for_list(fiction, viewer).exists?
    end

    def chapters_scope_for_list(fiction, viewer)
      return fiction.chapters if viewer&.admin?

      chapters_scope_by_visibility(fiction, viewer)
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

    def group_by_number_range(chapters)
      chapters.group_by do |chapter|
        if chapter.number.to_i.zero?
          '1-100'
        else
          range_start = (((chapter.number.to_i - 1) / 100) * 100) + 1
          range_end = range_start + 99
          "#{range_start}-#{range_end}"
        end
      end
    end

    # Guests: only chapters already public. Team on this fiction: also chapters with future published_at they scanlate.
    def chapters_scope_by_visibility(fiction, viewer)
      now = Time.current
      released_sql = visible_to_everyone_sql_fragment
      return fiction.chapters.where(released_sql, now) if guest_or_no_team_overlap?(fiction, viewer)

      fiction.chapters.where(sql_visible_now_or_future_for_team(released_sql), now, now, viewer.scanlators.ids)
    end
    module_function :chapters_scope_by_visibility

    def guest_or_no_team_overlap?(fiction, viewer)
      viewer.nil? || !viewer.scanlators.ids.intersect?(fiction.scanlators.ids)
    end
    module_function :guest_or_no_team_overlap?

    def visible_to_everyone_sql_fragment
      '(chapters.published_at IS NULL OR chapters.published_at <= ?)'
    end
    module_function :visible_to_everyone_sql_fragment

    def sql_visible_now_or_future_for_team(visible_to_all_sql)
      "#{visible_to_all_sql} OR (chapters.published_at > ? AND EXISTS (" \
        'SELECT 1 FROM chapter_scanlators cs WHERE cs.chapter_id = chapters.id AND cs.scanlator_id IN (?)))'
    end
    module_function :sql_visible_now_or_future_for_team
  end
end
