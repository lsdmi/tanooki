# frozen_string_literal: true

require 'test_helper'

class ReadingProgressTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @reading_progress = reading_progresses(:one)
  end

  test 'fiction_description returns correct description' do
    assert_equal @fiction.description, @reading_progress.fiction_description
  end

  test 'fiction_title returns correct title' do
    assert_equal @fiction.title, @reading_progress.fiction_title
  end
end
