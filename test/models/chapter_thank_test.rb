# frozen_string_literal: true

require 'test_helper'

class ChapterThankTest < ActiveSupport::TestCase
  setup do
    @chapter = chapters(:one)
    @user = users(:user_two)
  end

  test 'a reader thanks a chapter once' do
    ChapterThank.create!(user: @user, chapter: @chapter)
    duplicate = ChapterThank.new(user: @user, chapter: @chapter)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], 'можна подякувати за розділ лише один раз'
  end

  test 'the chapter counts its thanks' do
    thank = ChapterThank.create!(user: @user, chapter: @chapter)

    assert_equal 1, @chapter.reload.thanks_count

    thank.destroy!

    assert_equal 0, @chapter.reload.thanks_count
  end

  test 'thanked_by? knows the reader and answers false for a guest' do
    ChapterThank.create!(user: @user, chapter: @chapter)

    assert @chapter.thanked_by?(@user)
    assert_not @chapter.thanked_by?(users(:user_one))
    assert_not @chapter.thanked_by?(nil)
  end

  test 'thanked_by? reads preloaded thanks without a query' do
    ChapterThank.create!(user: @user, chapter: @chapter)
    chapter = Chapter.includes(:chapter_thanks).find(@chapter.id)

    assert_no_queries { assert chapter.thanked_by?(@user) }
  end
end
