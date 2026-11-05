# frozen_string_literal: true

# View helpers for public contest pages and the one-screen submission form.
module ContestsHelper
  def contests_publicly_visible?
    Contests::PublicAccess.visible?(current_user)
  end

  def contest_submit_requirements_line(contest)
    kind = t("contests.kinds.#{contest.kind}").downcase
    parts = [
      contest.requires_new_work? ? t('contests.submit.req.new_kind', kind:) : kind,
      t('contests.submit.req.deadline', date: l(contest.submissions_close_at.to_date, format: :long))
    ]
    volume = contest_submit_volume_parts(contest)
    parts << volume.join(' · ') if volume.any?
    parts.join(' · ')
  end

  def contest_submit_volume_parts(contest)
    volume = []
    volume << t('contests.submit.req.chapters', count: contest.min_chapters) if contest.min_chapters
    if contest.min_words
      volume << t('contests.submit.req.words', count: number_with_delimiter(contest.min_words, delimiter: ' '))
    end
    volume
  end

  def contest_entry_for_fiction(fiction)
    return if fiction.blank?

    fiction.contest_entries.active.includes(:contest).order(submitted_at: :desc).first
  end
end
