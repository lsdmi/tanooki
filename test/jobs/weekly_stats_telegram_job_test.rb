# frozen_string_literal: true

require 'test_helper'

class WeeklyStatsTelegramJobTest < ActiveSupport::TestCase
  setup do
    @wednesday = Time.zone.parse('2026-05-07 14:00')
  end

  test 'perform sends weekly digest HTML to Telegram' do
    travel_to @wednesday do
      seed_weekly_stats_fixture_data!
      expected_text = WeeklyStatsTelegramJob.new.send(:text_message)
      sent = capture_telegram_weekly_send

      assert_equal(
        { chat_id: '@bakaInUa', text: expected_text, parse_mode: 'HTML' },
        sent
      )
    end
  end

  private

  def capture_telegram_weekly_send
    slot = []
    api = Minitest::Mock.new
    api.expect(:send_message, nil) { |p| slot[0] = p }
    bot = Minitest::Mock.new
    bot.expect(:api, api)
    TelegramBot.stub(:client, bot) { WeeklyStatsTelegramJob.new.send(:send_weekly_digest_to_telegram) }
    api.verify && bot.verify
    slot[0]
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

  def seed_weekly_stats_fixture_data!
    seed_chapter_timestamps!
    seed_reading_progress_timestamps!
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
