# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PersistTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @chapter = Chapter.new(user: @user)
    end

    test 'draft intent skips content minimum and clears published_at' do
      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(content: 'short', published_at: 1.day.from_now),
        intent: 'draft',
        user: @user
      )

      assert saved
      assert_predicate @chapter, :draft?
      assert_nil @chapter.published_at
    end

    test 'unknown intent publishes' do
      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(content: 'x' * 500),
        intent: 'nope',
        user: @user
      )

      assert saved
      assert_predicate @chapter, :published?
    end

    test 'publish intent still requires content minimum' do
      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(content: 'short'),
        intent: 'publish',
        user: @user
      )

      assert_not saved
      assert_predicate @chapter, :published?
    end

    test 'failed publish on an existing draft keeps draft status for redisplay' do
      Persist.call(chapter: @chapter, attributes: persist_attrs(content: 'short'), intent: 'draft', user: @user)

      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(content: 'short', number: @chapter.number),
        intent: 'publish',
        user: @user
      )

      assert_not saved
      assert_predicate @chapter, :draft?
    end

    test 'draft intent unpublishes a live chapter and drops catalog slots' do
      Persist.call(chapter: @chapter, attributes: persist_attrs, intent: 'publish', user: @user)
      slots_before = Catalog::ChapterSlots.call(@fiction.reload)

      saved = Persist.call(
        chapter: @chapter,
        attributes: persist_attrs(title: 'Now a draft', number: @chapter.number),
        intent: 'draft',
        user: @user
      )

      assert saved
      assert_predicate @chapter.reload, :draft?
      assert_equal slots_before - 1, Catalog::ChapterSlots.call(@fiction.reload)
    end

    private

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
