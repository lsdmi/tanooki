# frozen_string_literal: true

require 'test_helper'

class FictionChapterListManagerTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @chapter_one = chapters(:one)
    @chapter_two = chapters(:two)
    @chapter_three = chapters(:three)
  end

  test 'should return correct translator id for single chapter' do
    @fiction.chapters << @chapter_one
    manager = FictionChapterListManager.new(@fiction, [], 1)
    assert_equal [1], manager.translator
  end
end
