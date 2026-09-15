# frozen_string_literal: true

require 'test_helper'

module Chapters
  class FormHelperTest < ActionView::TestCase
    include FormHelper

    test 'show_chapter_draft_save? is true for new records' do
      assert show_chapter_draft_save?(Chapter.new)
    end

    test 'show_chapter_draft_save? is true for drafts' do
      chapter = chapters(:one)
      chapter.status = :draft

      assert show_chapter_draft_save?(chapter)
    end

    test 'show_chapter_draft_save? is false for published chapters' do
      assert_not show_chapter_draft_save?(chapters(:one))
    end
  end
end
