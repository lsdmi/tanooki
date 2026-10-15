# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ContentStatsBackfillJobTest < ActiveSupport::TestCase
    test 'writes word_count excerpt and body_bytes for existing chapters' do
      chapter = chapters(:one)
      chapter.scanlator_ids = chapter.scanlators.ids
      chapter.content = "<p>#{Array.new(120, 'слово').join(' ')}</p>"
      chapter.save!

      chapter = Chapter.find(chapter.id)
      chapter.assign_attributes(word_count: 0, body_bytes: 0, excerpt: nil)
      chapter.save!(validate: false)

      ContentStatsBackfillJob.perform_now(0)

      chapter.reload

      assert_equal 120, chapter.word_count
      assert_includes chapter.excerpt, 'слово'
      assert_operator chapter.body_bytes, :>, 0
    end
  end
end
