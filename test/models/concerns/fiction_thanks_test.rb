# frozen_string_literal: true

require 'test_helper'

class FictionThanksTest < ActiveSupport::TestCase
  test 'sums chapter thanks counters' do
    fiction = fictions(:one)
    chapter = fiction.chapters.first
    ChapterThank.find_by(user: users(:user_two), chapter:)&.destroy!
    ChapterThank.create!(user: users(:user_two), chapter:)

    assert_operator chapter.reload.thanks_count, :>=, 1
    assert_equal fiction.chapters.sum(:thanks_count), fiction.thanks_count
  end
end
