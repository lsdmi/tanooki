# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PersistReleaseTimeTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @chapter = Chapter.new(user: @user)
    end

    test 'publishing a draft without a schedule stamps published_at now' do
      create_old_draft
      saved = publish_without_schedule

      assert saved
      assert_predicate @chapter.reload, :published?
      assert_in_delta Time.current, @chapter.published_at, 2.seconds
    end

    test 'publishing a draft keeps created_at and uses now as public_at' do
      create_old_draft
      created_at = @chapter.reload.created_at
      publish_without_schedule
      @chapter.reload

      assert_in_delta created_at, @chapter.created_at, 2.seconds
      assert_in_delta Time.current, @chapter.public_at, 2.seconds
    end

    test 'publishing a draft refreshes last_chapter_at to now' do
      create_old_draft
      publish_without_schedule

      assert_in_delta Time.current, @fiction.reload.last_chapter_at, 2.seconds
    end

    test 'publishing a draft with a schedule keeps the scheduled time' do
      Persist.call(chapter: @chapter, attributes: persist_attrs(content: 'short'), intent: 'draft', user: @user)
      scheduled = 2.days.from_now.change(usec: 0)

      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(number: @chapter.number, published_at: scheduled),
        intent: 'publish',
        user: @user
      )

      assert saved
      assert_in_delta scheduled, @chapter.reload.published_at, 1.second
      assert_predicate @chapter, :scheduled?
    end

    test 'editing a live chapter without a schedule does not bump published_at' do
      create_old_draft
      publish_without_schedule
      original = @chapter.reload.published_at

      travel_to 1.hour.from_now do
        saved = Persist.call(
          chapter: @chapter,
          attributes: persist_attrs(title: 'Edited live', number: @chapter.number, published_at: nil),
          intent: 'publish',
          user: @user
        )

        assert saved
        assert_in_delta original, @chapter.reload.published_at, 1.second
      end
    end

    test 'clearing a future schedule publishes immediately with a fresh time' do
      Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(published_at: 2.days.from_now),
        intent: 'publish',
        user: @user
      )

      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(number: @chapter.number, published_at: nil),
        intent: 'publish',
        user: @user
      )
      @chapter.reload

      assert saved
      assert_not @chapter.scheduled?
      assert_in_delta Time.current, @chapter.published_at, 2.seconds
    end

    private

    def create_old_draft
      travel_to 3.days.ago do
        Persist.call(chapter: @chapter, attributes: persist_attrs(content: 'x' * 500), intent: 'draft', user: @user)
      end
    end

    def publish_without_schedule
      Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(number: @chapter.number, published_at: nil),
        intent: 'publish',
        user: @user
      )
    end

    def persist_attrs(**overrides)
      {
        content: 'x' * 500,
        fiction_id: @fiction.id,
        number: 88,
        scanlator_ids: [scanlators(:one).id.to_s],
        title: 'Persist chapter'
      }.merge(overrides)
    end
  end
end
