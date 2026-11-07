# frozen_string_literal: true

module Contests
  # Section matrix, role, and actions for the public contest page (CONTESTS.md 8.3-8.4); tables in ShowMatrix.
  class ShowPresenter
    ENTRY_STATUSES = (ContestEntry::ACTIVE_STATUSES + %w[rejected]).freeze
    RESULTS_ORDER_SQL = 'contest_entries.final_rank IS NULL, contest_entries.final_rank ASC, contest_entries.id ASC'

    attr_reader :contest, :user

    def initialize(contest:, user:)
      @contest = contest
      @user = user
    end

    def phase
      @phase ||= contest.phase
    end

    def role
      @role ||= if user.blank? then :guest
                elsif user.admin? then :admin
                elsif my_entry.present? then :participant
                else :reader
                end
    end

    # { label_key:, label_args:, href:, kind: } or nil when the matrix has no action (e.g. admin on cancelled).
    # kind is :anchor (same page), :path (internal route) or :external.
    def primary_action
      return @primary_action if defined?(@primary_action)

      @primary_action = actions.primary
    end

    def secondary_action
      return @secondary_action if defined?(@secondary_action)

      @secondary_action = actions.secondary
    end

    # Ordered sections: [{ id:, anchor:, partial_or_component:, nav:, visible: }].
    def sections
      @sections ||= ShowSections.new(self).call
    end

    def visible_sections
      sections.select { |section| section[:visible] }
    end

    # Anchor links for the sticky section bar: visible sections that have a nav label.
    def nav_items
      visible_sections.flat_map do |section|
        links = section[:nav_links].presence || [{ nav: section[:nav], anchor: section[:anchor] }]
        links.filter_map do |link|
          next if link[:nav].blank?

          { id: section[:id], anchor: link[:anchor], label_key: "contests.show.nav.#{link[:nav]}" }
        end
      end
    end

    # Six facts, the same for every contest: [{ key:, label:, value: }].
    def summary_facts
      @summary_facts ||= SummaryFacts.new(contest, prize_pool_total:).call
    end

    # Accepted/qualified entries with a fiction that has a released chapter. Seeded-random before results.
    def gallery_entries
      contest.entries.gallery.where.not(fiction_id: nil)
             .where(fiction_id: Chapter.released.select(:fiction_id))
             .includes(fiction: [{ cover_attachment: :blob }, :genres])
             .order(Arel.sql(gallery_order_sql))
    end

    # The user's own entry (active or rejected); an active one wins over a rejected one.
    def my_entry
      return if user.blank?
      return @my_entry if defined?(@my_entry)

      @my_entry = own_entries.min_by { |entry| [entry.rejected? ? 1 : 0, -entry.submitted_at.to_i] }
    end

    # Steps announced -> submissions -> judging -> awaiting_results -> results; key matches the phase name.
    def timeline_steps
      @timeline_steps ||= [
        [:announced, contest.announced_at],
        [:submissions, contest.submissions_open_at],
        [:judging, contest.submissions_close_at],
        [:awaiting_results, contest.judging_close_at],
        [:results, contest.results_published_at]
      ].map { |key, at| { key:, at:, current: key == phase } }
    end

    def prize_pool_total
      contest.prize_pool_uah + contest.donations_uah + contest.carryover_uah
    end

    # Prizes with a donation unlock threshold, lowest first.
    def donation_goals
      @donation_goals ||= contest.prizes.where.not(unlock_at_uah: nil).order(:unlock_at_uah).to_a
    end

    def past_winners?
      past_winners.any?
    end

    # Winners of earlier contests (this one excluded).
    def past_winners
      @past_winners ||= HubPresenter.new.hall_of_fame(limit: 4, except: contest).to_a
    end

    private

    def actions
      @actions ||= ShowActions.new(self)
    end

    def own_entries
      base = contest.entries.where(status: ENTRY_STATUSES)
      base.where(submitter_id: user.id)
          .or(base.where(id: ContestEntryAuthor.where(user_id: user.id).select(:contest_entry_id)))
    end

    # Deterministic per contest and day; CRC32 keeps the order stable without a RAND() seed quirk.
    def gallery_order_sql
      return RESULTS_ORDER_SQL if phase == :results

      ActiveRecord::Base.sanitize_sql_array(
        ['CRC32(CONCAT(contest_entries.id, ?)), contest_entries.id', "#{contest.id}-#{Date.current.iso8601}"]
      )
    end
  end
end
