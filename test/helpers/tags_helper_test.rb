# frozen_string_literal: true

require 'test_helper'

class TagsHelperTest < ActionView::TestCase
  include ApplicationHelper
  include TagsHelper

  def setup
    @tag = Publication.new(title: 'A tag', description: 'A description.')
  end

  test "main_state should return 'hidden lg:block' if title size is greater than 85" do
    @tag.title = 'A' * 86
    assert_equal 'hidden lg:block', main_state(@tag)
  end

  test "main_state should return 'hidden lg:block' if available space is negative" do
    @tag.title = 'A'
    @tag.description = 'A' * 150
    assert_equal 'hidden lg:block', main_state(@tag)
  end

  test "main_state should return 'hidden sm:block' if available space is positive" do
    assert_equal 'hidden sm:block', main_state(@tag)
  end
end
