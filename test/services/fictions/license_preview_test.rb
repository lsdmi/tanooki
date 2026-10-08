# frozen_string_literal: true

require 'test_helper'

module Fictions
  class LicensePreviewTest < ActiveSupport::TestCase
    setup do
      @fiction = fictions(:one)
      @extra = (3..8).map { |number| add_chapter(number) }
    end

    test 'the first six released chapters stay readable and the rest is hidden' do
      preview = LicensePreview.new(@fiction)

      assert_equal [chapters(:one), chapters(:two), *@extra.first(4)].map(&:id).sort, preview.chapter_ids.sort
      assert_equal [6, 8, 2], [preview.available_count, preview.released_count, preview.hidden_count]
      assert_equal %w[1–6 7–8], [preview.available_range, preview.hidden_range]
    end

    test 'a chapter translated twice counts once and keeps both translations' do
      second = add_chapter(1, scanlator: scanlators(:two))
      preview = LicensePreview.new(@fiction)

      assert_includes preview.chapter_ids, second.id
      assert_equal 6, preview.available_count
    end

    test 'drafts are neither previewed nor hidden' do
      @extra.last.update!(status: :draft)
      preview = LicensePreview.new(@fiction)

      assert_equal [1, '7'], [preview.hidden_count, preview.hidden_range]
      assert preview.hidden_number?(7)
      assert_not preview.hidden_number?(6)
    end

    private

    def add_chapter(number, scanlator: scanlators(:one))
      Chapter.create!(fiction: @fiction, user: users(:user_one), title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlator.id])
    end
  end
end
