# frozen_string_literal: true

require 'test_helper'

module Reading
  class GuestRecordTest < ActiveSupport::TestCase
    test 'parses ids, reads, resume_at and the locator' do
      record = GuestRecord.parse(fiction_id: '1', chapter_id: 2, read_chapter_ids: [2, '1', 2],
                                 resume_at: '2026-09-29T12:00:00.000Z', locator: { percent: 40 })

      assert_equal [1, 2, [2, 1]], [record.fiction_id, record.chapter_id, record.read_chapter_ids]
      assert_equal [Time.utc(2026, 9, 29, 12), 40.0], [record.resume_at, record.locator.percent]
    end

    test 'drops malformed parts' do
      record = GuestRecord.parse(fiction_id: 1, chapter_id: 'x', read_chapter_ids: [3, -1, nil, 'y'],
                                 resume_at: 'yesterday', locator: { percent: 'far' })

      assert_equal [nil, [3], nil, nil], [record.chapter_id, record.read_chapter_ids, record.resume_at, record.locator]
    end

    test 'a resume_at from a clock set ahead is taken as now' do
      freeze_time do
        record = GuestRecord.parse(fiction_id: 1, chapter_id: 2, resume_at: 1.day.from_now.iso8601)

        assert_equal Time.current, record.resume_at
      end
    end

    test 'needs a fiction and a chapter to resume or a read' do
      assert_nil GuestRecord.parse(chapter_id: 2, read_chapter_ids: [2])
      assert_nil GuestRecord.parse(fiction_id: 1, read_chapter_ids: [])
      assert_nil GuestRecord.parse('junk')
    end

    test 'reads alone are enough to merge' do
      assert_equal [4], GuestRecord.parse(fiction_id: 1, read_chapter_ids: [4]).read_chapter_ids
    end
  end
end
