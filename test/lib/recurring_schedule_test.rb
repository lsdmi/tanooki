# frozen_string_literal: true

require 'test_helper'

class RecurringScheduleTest < ActiveSupport::TestCase
  setup do
    raw = Rails.root.join('config/recurring.yml').read
    @tasks = YAML.safe_load(ERB.new(raw).result).fetch('production').to_h do |key, options|
      [key, SolidQueue::RecurringTask.from_configuration(key, **options.symbolize_keys)]
    end
  end

  test 'every production task is valid' do
    invalid = @tasks.values.reject(&:valid?).map { |task| "#{task.key}: #{task.errors.full_messages.to_sentence}" }

    assert_empty invalid
  end

  test 'every schedule names its zone because the container runs in UTC' do
    @tasks.each_value { |task| assert_match(%r{ (Europe/Kiev|UTC)\z}, task.schedule, task.key) }
  end

  test 'nightly jobs run at the intended Kyiv time' do
    { 'purge_expired_epub_exports' => '04:00', 'purge_orphan_chapter_images' => '04:20',
      'sync_youtube_videos' => '00:00' }.each do |key, kyiv_time|
      assert_equal kyiv_time, kyiv(@tasks.fetch(key).next_time).strftime('%H:%M'), key
    end
  end

  test 'telegram digests post on their weekday and hour in Kyiv' do
    { 'youtube' => 'Sun 12:00', 'weekly_stats' => 'Wed 15:00',
      'fictions' => 'Thu 14:00', 'publications' => 'Fri 15:00' }.each do |digest, kyiv_slot|
      task = @tasks.fetch("telegram_digest_#{digest}")

      assert_equal [digest], task.arguments
      assert_equal kyiv_slot, kyiv(task.next_time).strftime('%a %H:%M'), digest
    end
  end

  private

  def kyiv(time)
    time.in_time_zone('Europe/Kiev')
  end
end
