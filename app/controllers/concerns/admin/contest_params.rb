# frozen_string_literal: true

module Admin
  # Strong params and new-contest defaults for Admin::ContestsController.
  module ContestParams
    DEFAULT_PRIZES = [
      { position: 0, title: '1 місце', kind: 'place', place: 1 },
      { position: 1, title: '2 місце', kind: 'place', place: 2 },
      { position: 2, title: '3 місце', kind: 'place', place: 3 }
    ].freeze

    CONTEST_PERMITTED = [
      :title, :tagline, :kind, :teaser_text, :description, :rules,
      :announced_at, :submissions_open_at, :submissions_close_at, :judging_close_at,
      :required_genre_id, :requires_new_work, :requires_completed,
      :min_chapters, :judged_chapters_scope,
      :max_content_rating, :max_entries_per_user, :jury_weight,
      :prize_pool_uah, :donations_uah, :donation_url, :carryover_uah,
      :cover, :entry_placeholder_cover,
      { prizes_attributes: [%i[id title kind place position cash_uah unlock_at_uah perks _destroy]],
        jurors_attributes: [%i[id user_id role public_bio _destroy]] }
    ].freeze

    private

    def default_contest_attributes
      open_at = 4.weeks.from_now.change(hour: 0, min: 0, sec: 0)
      default_contest_schedule(open_at).merge(default_contest_rules, default_contest_limits)
    end

    def default_contest_schedule(open_at)
      {
        kind: 'original',
        announced_at: Time.current,
        submissions_open_at: open_at,
        submissions_close_at: open_at + 10.weeks,
        judging_close_at: open_at + 13.weeks
      }
    end

    def default_contest_rules
      { requires_new_work: true, min_chapters: 3 }
    end

    def default_contest_limits
      {
        max_content_rating: 18,
        max_entries_per_user: 1,
        jury_weight: 60,
        required_genre_id: Genre.find_by(slug: Genre::ORIGINAL_SLUG)&.id,
        prize_pool_uah: 0
      }
    end

    def contest_params
      params.expect(contest: CONTEST_PERMITTED)
    end
  end
end
