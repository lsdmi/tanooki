# frozen_string_literal: true

require 'test_helper'

class TagsHelperTest < ActionView::TestCase
  include ApplicationHelper
  include TagsHelper

  def setup
    @new_publication = Publication.new(title: 'A tag', description: 'A description.')
    @publication = publications(:tale_approved_one)
  end

  test "main_state should return 'hidden lg:block' if title size is greater than 85" do
    @new_publication.title = 'A' * 86
    assert_equal 'hidden lg:block', main_state(@new_publication)
  end

  test "main_state should return 'hidden lg:block' if available space is negative" do
    @new_publication.title = 'A'
    @new_publication.description = 'A' * 150
    assert_equal 'hidden lg:block', main_state(@new_publication)
  end

  test "main_state should return 'hidden sm:block' if available space is positive" do
    assert_equal 'hidden sm:block', main_state(@new_publication)
  end
end
