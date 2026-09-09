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
        UpdateListingEditorial.call(@fiction, complete: true)
        @fiction.save!

        assert_equal Time.current, @fiction.reload.completed_at

        travel 1.day
        UpdateListingEditorial.call(@fiction, complete: true)
        @fiction.save!

        assert_equal 1.day.ago, @fiction.reload.completed_at
      end
    end

    test 'unchecking complete clears completed_at' do
      @fiction.update!(completed_at: Time.current)

      UpdateListingEditorial.call(@fiction, complete: false)
      @fiction.save!

      assert_nil @fiction.reload.completed_at
    end

    test 'rejects expected_chapters below the live chapter_count' do
      @fiction.chapter_count = 10
      UpdateListingEditorial.call(@fiction, expected: 3)

      assert_not @fiction.valid?
      assert_not_empty @fiction.errors[:expected_chapters]
    end
  end
end
