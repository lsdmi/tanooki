# frozen_string_literal: true

module WeeklyDigestFixtureHelpers
  def seed_weekly_digest_fixture_data!
    seed_chapter_timestamps!
    seed_reading_progress_timestamps!
  end

  def seed_chapter_timestamps!
    seed_chapter_schedule!(chapters(:one), created_at: Time.zone.parse('2026-05-05 10:00'), views: 1)
    seed_chapter_schedule!(chapters(:three), created_at: Time.zone.parse('2026-05-06 10:00'), views: 1)
    seed_chapter_schedule!(chapters(:two), created_at: Time.zone.parse('2026-04-28 10:00'), views: 500)
  end

  def seed_reading_progress_timestamps!
    reading_progresses(:one).update!(updated_at: Time.zone.parse('2026-04-29 12:00'))
    reading_progresses(:two).update!(updated_at: Time.zone.parse('2026-04-30 12:00'))
    reading_progresses(:three).update!(updated_at: Time.zone.parse('2026-05-01 12:00'))
  end

  def seed_chapter_schedule!(chapter, created_at:, views:)
    attrs = {
      created_at: created_at,
      published_at: nil,
      views: views,
      scanlator_ids: chapter.scanlators.ids.presence || [scanlators(:one).id]
    }
    attrs[:content] = ('a' * 500) if chapter_needs_placeholder_content?(chapter)
    chapter.update!(attrs)
  end

  def chapter_needs_placeholder_content?(chapter)
    return true if chapter.content.blank?

    chapter.content.body.present? && chapter.content.body.to_plain_text.length < 500
  end
end
