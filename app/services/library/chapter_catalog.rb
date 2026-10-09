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

    # Loaded rows, shared by every caller in the request. Freshly changed chapters need ordered_chapters.
    def listed_chapters(fiction, viewer: nil, order: :desc)
      descending = order.to_sym == :desc
      RequestMemo.remember(:listed_chapters, fiction.id, viewer&.id, descending) do
        scope = descending ? ordered_chapters_desc(fiction, viewer:) : ordered_chapters(fiction, viewer:)
        scope.to_a.freeze
      end
    end

    def listed_chapters_with_scanlators(fiction, viewer: nil)
      listed_chapters(fiction, viewer:).tap do |list|
        ActiveRecord::Associations::Preloader.new(records: list, associations: :scanlators).call
      end
    end

    def ordered_user_chapters_desc(fiction, user)
      base = fiction.chapters.order(user_chapters_order_clause)
      return base if user.admin?

      base.joins(:scanlators).where(scanlators: { id: viewer_scanlator_ids(user) }).distinct
    end

    def chapters_size(fiction, viewer: nil)
      ChapterNavigation.unique_chapters(listed_chapters(fiction, viewer:)).size
    end

    # The fiction and reader pages render the list right after this check, so it costs no extra query.
    def fiction_has_listable_chapters?(fiction, viewer)
      listed_chapters(fiction, viewer:).any?
    end

    # Within one volume or number range the ascending order is the descending one reversed.
    def listed_section_chapters(fiction, chapter_ids, viewer: nil, order: :desc, scanlators: false)
      ids = chapter_ids.to_set
      chapters = listed_chapters(fiction, viewer:).select { |chapter| ids.include?(chapter.id) }
      ActiveRecord::Associations::Preloader.new(records: chapters, associations: :scanlators).call if scanlators
      order.to_sym == :desc ? chapters : chapters.reverse
    end

    # On a licensed work everyone, admins included, gets only the preview, or nothing after the takedown.
    def chapters_scope_for_list(fiction, viewer)
      scope = viewer&.admin? ? fiction.chapters.published : chapters_scope_by_visibility(fiction, viewer)
      fiction.licensed? ? scope.where(id: fiction.license_readable_chapter_ids) : scope
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

    def user_chapters_order_clause
      draft_first = ActiveRecord::Base.sanitize_sql_array(
        ['CASE WHEN chapters.status = ? THEN 0 ELSE 1 END', Chapter.statuses[:draft]]
      )
      Arel.sql("#{draft_first}, COALESCE(volume_number, 0) DESC, number DESC, #{Chapter::PUBLIC_TIME_SQL} DESC")
    end

    # Guests: only chapters already public. Team on this fiction: also scheduled rows they scanlate.
    # Drafts stay off this list (they belong on readings#show via ordered_user_chapters_desc).
    def chapters_scope_by_visibility(fiction, viewer)
      now = Time.current
      released_sql = visible_to_everyone_sql_fragment
      return fiction.chapters.where(released_sql, now) if guest_or_no_team_overlap?(fiction, viewer)

      fiction.chapters.where(sql_visible_now_or_future_for_team(released_sql), now, now, viewer_scanlator_ids(viewer))
    end
    module_function :chapters_scope_by_visibility

    def guest_or_no_team_overlap?(fiction, viewer)
      return true if viewer.nil?

      fiction_ids = RequestMemo.remember(:fiction_scanlator_ids, fiction.id) { fiction.scanlators.ids }
      !viewer_scanlator_ids(viewer).intersect?(fiction_ids)
    end
    module_function :guest_or_no_team_overlap?

    def viewer_scanlator_ids(viewer)
      RequestMemo.remember(:viewer_scanlator_ids, viewer.id) { viewer.scanlators.ids }
    end
    module_function :viewer_scanlator_ids

    def visible_to_everyone_sql_fragment
      "(#{published_status_sql} AND (chapters.published_at IS NULL OR chapters.published_at <= ?))"
    end
    module_function :visible_to_everyone_sql_fragment

    def sql_visible_now_or_future_for_team(visible_to_all_sql)
      "#{visible_to_all_sql} OR (#{published_status_sql} AND chapters.published_at > ? AND EXISTS (" \
        'SELECT 1 FROM chapter_scanlators cs WHERE cs.chapter_id = chapters.id AND cs.scanlator_id IN (?)))'
    end
    module_function :sql_visible_now_or_future_for_team

    def published_status_sql
      ActiveRecord::Base.sanitize_sql_array(['chapters.status = ?', Chapter.statuses[:published]])
    end
    module_function :published_status_sql
  end
end
