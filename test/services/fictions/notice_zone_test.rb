# frozen_string_literal: true

require 'test_helper'

module Fictions
  class NoticeZoneTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.assign_attributes(content_rating: :everyone, completed_at: nil, chapter_count: 3,
                                 last_chapter_at: 1.day.ago)
    end

    test 'an ongoing everyone-rated fiction has no notices' do
      assert_empty NoticeZone.for(@fiction)
    end

    test 'each listing state maps to its status notice' do
      kinds = {
        stale: { last_chapter_at: 4.months.ago },
        announced: { chapter_count: 0, last_chapter_at: nil },
        finished: { completed_at: 1.day.ago }
      }.transform_values { |attrs| NoticeZone.for(@fiction.dup.tap { |f| f.assign_attributes(attrs) }).map(&:kind) }

      assert_equal({ stale: [:dropped], announced: [:announced], finished: [:finished] }, kinds)
    end

    test 'the age notice comes first and can be left out' do
      @fiction.assign_attributes(content_rating: :eighteen, completed_at: 1.day.ago)

      assert_equal %i[adult finished], NoticeZone.for(@fiction).map(&:kind)
      assert_equal %i[finished], NoticeZone.for(@fiction, age: false).map(&:kind)
    end

    test 'a licensed fiction gets the licensed notice whatever its listing state' do
      @fiction.assign_attributes(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест',
                                 last_chapter_at: 4.months.ago)

      notice = NoticeZone.for(@fiction).sole

      assert_equal :licensed, notice.kind
      assert_includes notice.body, '«Видавництво Тест»'
    end

    test 'the licensed notice reads without a publisher' do
      @fiction.assign_attributes(licensed_at: 1.day.ago, license_url: 'https://example.com/book')

      assert_equal 'Твір ліцензовано в Україні. Опубліковані розділи лишаються доступними, нових на сайті не буде.',
                   NoticeZone.for(@fiction).sole.body
    end

    test 'notices carry the uk copy' do
      notice = NoticeZone.notice(:teen)

      assert_equal ['Контент 16+', 'Твір містить сцени, які можуть не підходити читачам до 16 років.'],
                   [notice.title, notice.body]
    end
  end
end
