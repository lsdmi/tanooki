# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ContentStatsTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @chapter.scanlator_ids = @chapter.scanlators.ids
      @words = Array.new(120, 'слово')
      @body = "<p>#{@words.join(' ')}</p>"
      @chapter.content = @body
    end

    test 'attributes_for fills word_count excerpt and body_bytes' do
      stats = ContentStats.attributes_for(@chapter)

      assert_equal 120, stats[:word_count]
      assert_includes stats[:excerpt], 'слово'
      assert_operator stats[:body_bytes], :>, 0
    end

    test 'save refreshes stats when content is loaded' do
      @chapter.save!

      assert_equal 120, @chapter.word_count
      assert_includes @chapter.excerpt, 'слово'
      assert_operator @chapter.body_bytes, :>, 0
    end

    # Published chapters validate content length, which loads the body; drafts skip that check.
    test 'draft save without loading content leaves stats alone' do
      @chapter.save!
      chapter = Chapter.find(@chapter.id)
      chapter.assign_attributes(status: 'draft', word_count: 99, body_bytes: 99, excerpt: 'keep')
      chapter.save!(validate: false)

      chapter = Chapter.find(@chapter.id)
      chapter.scanlator_ids = chapter.scanlators.ids
      chapter.update!(title: 'Only title')

      assert_equal 99, chapter.reload.word_count
      assert_equal 'keep', chapter.excerpt
    end
  end
end
