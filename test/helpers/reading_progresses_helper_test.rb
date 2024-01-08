# frozen_string_literal: true

require 'test_helper'

class ReadingProgressesHelperTest < ActionView::TestCase
  include ReadingProgressesHelper

  test 'sweetalert_options returns correct options for reading progress' do
    reading_progress = reading_progresses(:one)

    options = sweetalert_options(reading_progress)

    assert_equal ReadingProgressesHelper::DESCRIPTION, options[:description]
    assert_equal ReadingProgressesHelper::MESSAGE, options[:message]
    assert_equal "progress_item-#{reading_progress.id}", options[:tag_id]
    assert_equal destroy_reading_progress_path(reading_progress), options[:url]
  end
end
