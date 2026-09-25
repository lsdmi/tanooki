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

  test 'rejects an out-of-range resume locator' do
    @reading_progress.assign_attributes(resume_percent: 101, resume_block_index: -1, resume_quote: 'я' * 121)

    assert_not @reading_progress.valid?
    assert_equal %i[resume_block_index resume_percent resume_quote], @reading_progress.errors.attribute_names.sort
  end
end
