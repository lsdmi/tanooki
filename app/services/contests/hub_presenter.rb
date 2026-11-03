# frozen_string_literal: true

module Contests
  # Data for the /contests hub: featured contest, archive, and hall of fame.
  class HubPresenter
    FEATURED_ACTIVE_PHASES = %i[submissions judging].freeze
    HALL_OF_FAME_PLACES = (1..3)
    HALL_OF_FAME_LIMIT = 12
    HIDDEN_ENTRY_STATUSES = %w[rejected withdrawn disqualified].freeze
    ARCHIVE_ORDER_SQL = 'COALESCE(contests.results_published_at, contests.cancelled_at) DESC'

    # Active (submissions/judging) contest first, else the soonest announced one, else nil.
    def featured
      return @featured if defined?(@featured)

      @featured = active_contest || announced_contest
    end

    def hub_state
      return :idle if featured.blank?

      FEATURED_ACTIVE_PHASES.include?(featured.phase) ? :active : :announced
    end

    # Unpublished draft with a public teaser line (between contests).
    def teaser_draft
      return @teaser_draft if defined?(@teaser_draft)

      @teaser_draft = Contest.where(published_at: nil)
                             .where.not(teaser_text: [nil, ''])
                             .order(:announced_at)
                             .first
    end

    # Published results and cancelled contests, newest first.
    def archive
      Contest.archived.order(Arel.sql(ARCHIVE_ORDER_SQL))
    end

    # Gallery entries per archived contest id, for archive cards.
    def entry_counts
      @entry_counts ||= ContestEntry.gallery.where(contest_id: archive.select(:id)).group(:contest_id).count
    end

    # Up to three fiction covers per archived contest (place order, then id).
    def archive_top_covers
      @archive_top_covers ||= archive_cover_rows.group_by(&:contest_id).transform_values do |entries|
        top_covers(entries)
      end
    end

    # Top-place awards of published results, newest contest first; covers are preloaded.
    def hall_of_fame(limit: HALL_OF_FAME_LIMIT, except: nil)
      scope = ContestAward.joins(:contest, :contest_prize, :contest_entry)
                          .where(contest_id: Contest.visible.where.not(results_published_at: nil).select(:id))
                          .where(contest_prizes: { kind: 'place', place: HALL_OF_FAME_PLACES })
                          .where.not(contest_entries: { status: HIDDEN_ENTRY_STATUSES })
      scope = scope.where.not(contest_id: except.id) if except
      scope.includes(:contest, :contest_prize, contest_entry: { fiction: { cover_attachment: :blob } })
           .order(Arel.sql('contests.results_published_at DESC, contest_prizes.place ASC, contest_awards.id ASC'))
           .limit(limit)
    end

    private

    def archive_cover_rows
      ContestEntry.gallery.where(contest_id: archive.select(:id))
                  .where.not(fiction_id: nil)
                  .includes(fiction: { cover_attachment: :blob })
                  .order(Arel.sql(<<~SQL.squish))
                    contest_entries.final_rank IS NULL,
                    contest_entries.final_rank ASC,
                    contest_entries.id ASC
                  SQL
    end

    def top_covers(entries)
      entries.first(3).filter_map { |entry| entry.fiction&.cover if entry.fiction&.cover&.attached? }
    end

    def active_contest
      Contest.active.order(:submissions_close_at).to_a
             .select { |contest| FEATURED_ACTIVE_PHASES.include?(contest.phase) }
             .min_by { |contest| FEATURED_ACTIVE_PHASES.index(contest.phase) }
    end

    def announced_contest
      Contest.active.order(:submissions_open_at).detect { |contest| contest.phase == :announced }
    end
  end
end
