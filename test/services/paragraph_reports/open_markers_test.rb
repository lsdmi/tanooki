# frozen_string_literal: true

require 'test_helper'

module ParagraphReports
  class OpenMarkersTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @digest = Chapters::ReaderContentHtml.new(@chapter).digest
      @other = users('user_101')
    end

    test 'returns markers with user + message for open reports matching the live digest' do
      seed_open_reports!

      assert_equal expected_markers, OpenMarkers.for(@chapter)
      assert_equal [0, 2], OpenMarkers.block_indices_for(@chapter)
    end

    test 'ignores fixed reports and empty chapters' do
      ParagraphReport.create!(
        user: users(:user_two),
        chapter: @chapter,
        block_index: 0,
        quote: 'Цитата',
        digest: @digest,
        status: :fixed,
        resolved_at: Time.current
      )

      assert_empty OpenMarkers.for(@chapter)
      assert_empty OpenMarkers.for(nil)
    end

    private

    def seed_open_reports!
      [
        [users(:user_two), 0, 'Тут калька'],
        [@other, 0, 'Другий читач'],
        [users(:user_two), 2, nil],
        [users(:user_two), 1, 'Не показувати', 'z' * ParagraphReport::DIGEST_LENGTH]
      ].each do |user, block_index, message, digest = @digest|
        ParagraphReport.create!(
          user:, chapter: @chapter, block_index:, quote: 'Цитата', digest:, message:
        )
      end
    end

    def expected_markers
      [
        {
          i: 0,
          m: [
            { u: users(:user_two).name, t: 'Тут калька', q: 'Цитата' },
            { u: @other.name, t: 'Другий читач', q: 'Цитата' }
          ]
        },
        { i: 2, m: [{ u: users(:user_two).name, t: '', q: 'Цитата' }] }
      ]
    end
  end
end
