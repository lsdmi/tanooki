# frozen_string_literal: true

require 'test_helper'

module Catalog
  class UpdateListingEditorialTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
    end

    test 'blank expected becomes nil' do
      @fiction.expected_chapters = 5

      UpdateListingEditorial.call(@fiction, expected: '')
      @fiction.save!

      assert_nil @fiction.reload.expected_chapters
    end

    test 'checking complete stamps completed_at once' do
      freeze_time do
        stamped = Time.current
        UpdateListingEditorial.call(@fiction, complete: true)
        @fiction.save!

        assert_equal stamped, @fiction.reload.completed_at

        travel 1.day
        UpdateListingEditorial.call(@fiction, complete: true)
        @fiction.save!

        assert_equal stamped, @fiction.reload.completed_at
      end
    end

    test 'unchecking complete clears completed_at and leaves a pause' do
      @fiction.update!(chapter_count: 2, completed_at: Time.current, paused_at: 2.days.ago)
      paused_at = @fiction.reload.paused_at

      UpdateListingEditorial.call(@fiction, complete: false)
      @fiction.save!

      assert_nil @fiction.reload.completed_at
      assert_equal paused_at, @fiction.paused_at
    end

    test 'checking complete clears a pause' do
      @fiction.update!(chapter_count: 2, paused_at: 1.day.ago)

      UpdateListingEditorial.call(@fiction, complete: true)
      @fiction.save!

      assert_nil @fiction.reload.paused_at
      assert_not_nil @fiction.completed_at
    end

    test 'ongoing clears both timestamps' do
      @fiction.update!(chapter_count: 2, paused_at: 1.day.ago, completed_at: Time.current)

      UpdateListingEditorial.call(@fiction, release: 'ongoing')
      @fiction.save!

      assert_nil @fiction.reload.paused_at
      assert_nil @fiction.completed_at
    end

    test 'pausing stamps paused_at once and clears completed_at' do
      @fiction.update!(chapter_count: 2, completed_at: Time.current)

      freeze_time do
        stamped = Time.current
        UpdateListingEditorial.call(@fiction, release: 'paused')
        @fiction.save!

        assert_equal stamped, @fiction.reload.paused_at
        assert_nil @fiction.completed_at

        travel 1.day
        UpdateListingEditorial.call(@fiction, release: 'paused')
        @fiction.save!

        assert_equal stamped, @fiction.reload.paused_at
      end
    end

    test 'finishing stamps completed_at and clears a pause' do
      @fiction.update!(chapter_count: 2, paused_at: 1.day.ago)

      UpdateListingEditorial.call(@fiction, release: 'finished')
      @fiction.save!

      assert_nil @fiction.reload.paused_at
      assert_not_nil @fiction.completed_at
    end

    test 'pausing with no chapters adds an error and does not persist' do
      @fiction.update!(chapter_count: 0, completed_at: Time.current)
      UpdateListingEditorial.call(@fiction, release: 'paused')

      assert_not @fiction.save
      assert_not_empty @fiction.errors[:paused_at]

      @fiction.reload

      assert_nil @fiction.paused_at
    end

    test 'a licensed listing ignores release paused' do
      @fiction.update!(chapter_count: 2, licensed_at: Time.current, license_publisher: 'Видавництво')

      UpdateListingEditorial.call(@fiction, release: 'paused')
      @fiction.save!

      assert_nil @fiction.reload.paused_at
    end

    test 'rejects expected_chapters below the live chapter_count' do
      @fiction.chapter_count = 10
      UpdateListingEditorial.call(@fiction, expected: 3)

      assert_not @fiction.valid?
      assert_not_empty @fiction.errors[:expected_chapters]
    end
  end
end
