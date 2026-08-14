# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressRecentInlineImagesJobTest < ActiveSupport::TestCase
    test 'enqueues compress jobs for chapters posted yesterday in production' do
      travel_to Time.zone.parse('2026-07-19 03:30:00') do
        stamp_chapter_dates
        enqueued = capture_staggered_enqueues do
          CompressRecentInlineImagesJob.new.perform(day: Date.parse('2026-07-19'))
        end

        assert_equal [{ chapter_id: chapters(:one).id, wait: 0.seconds }], enqueued
        assert_not_includes enqueued.pluck(:chapter_id), chapters(:two).id
      end
    end

    test 'does nothing outside production' do
      called = false
      stub_compress_set(->(*) { called = true }) { CompressRecentInlineImagesJob.new.perform }

      assert_not called
    end

    private

    def stamp_chapter_dates
      stamp(chapters(:one), published_at: '2026-07-18 12:00', created_at: '2026-07-10 12:00')
      stamp(chapters(:two), published_at: '2026-07-16 12:00', created_at: '2026-07-16 12:00')
      stamp(chapters(:three), published_at: nil, created_at: '2026-07-16 12:00')
    end

    def stamp(chapter, published_at:, created_at:)
      chapter.update_columns( # rubocop:disable Rails/SkipsModelValidations
        published_at: published_at && Time.zone.parse(published_at),
        created_at: Time.zone.parse(created_at)
      )
    end

    def capture_staggered_enqueues(&)
      enqueued = []
      Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
        stub_compress_set(->(chapter_id, wait:) { enqueued << { chapter_id:, wait: } }, &)
      end
      enqueued
    end

    def stub_compress_set(on_enqueue, &)
      CompressInlineImagesJob.stub(:set, ->(wait:) { compress_set_proxy(on_enqueue, wait:) }, &)
    end

    def compress_set_proxy(on_enqueue, wait:)
      Object.new.tap do |proxy|
        proxy.define_singleton_method(:perform_later) do |chapter_id|
          on_enqueue.call(chapter_id, wait:)
        end
      end
    end
  end
end
