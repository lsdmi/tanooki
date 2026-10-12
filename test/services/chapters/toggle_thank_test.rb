# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ToggleThankTest < ActiveSupport::TestCase
    setup do
      @chapter = chapters(:one)
      @user = users(:user_two)
    end

    test 'the first call thanks the chapter' do
      result = ToggleThank.call(chapter: @chapter, user: @user)

      assert result.ok
      assert result.thanked
      assert_equal 1, result.thanks_count
    end

    test 'the second call takes the thanks back' do
      ToggleThank.call(chapter: @chapter, user: @user)
      result = ToggleThank.call(chapter: @chapter, user: @user)

      assert result.ok
      assert_not result.thanked
      assert_equal 0, ChapterThank.where(chapter: @chapter).count
    end

    test 'the team cannot thank its own chapter' do
      ScanlatorUser.create!(scanlator: scanlators(:one), user: @user)

      assert_no_difference('ChapterThank.count') do
        assert_equal :own_work, ToggleThank.call(chapter: @chapter, user: @user).error
      end
    end

    test 'an admin cannot thank either' do
      assert_equal :own_work, ToggleThank.call(chapter: @chapter, user: users(:user_one)).error
    end

    test 'a draft or scheduled chapter cannot be thanked' do
      @chapter.update!(status: 'draft')

      assert_equal :not_released, ToggleThank.call(chapter: @chapter, user: @user).error

      @chapter.update!(status: 'published', published_at: 1.day.from_now)

      assert_equal :not_released, ToggleThank.call(chapter: @chapter, user: @user).error
    end

    test 'thanking clears the team stats cache' do
      cleared = []
      Scanlators::StatsCacheInvalidation.stub(:for_scanlator_ids, ->(ids) { cleared << ids }) do
        ToggleThank.call(chapter: @chapter, user: @user)
      end

      assert_includes cleared, [scanlators(:one).id]
    end
  end
end
