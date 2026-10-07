# frozen_string_literal: true

require 'test_helper'

module Chapters
  class PersistLicensedTest < ActiveSupport::TestCase
    setup do
      @user = users(:user_one)
      @fiction = fictions(:one)
      @fiction.scanlator_ids = @fiction.scanlators.ids
    end

    test 'a new chapter cannot be published on a licensed fiction' do
      license!
      chapter = Chapter.new(user: @user)

      assert_not persist(chapter, intent: 'publish')
      assert_predicate chapter, :new_record?
      assert_includes chapter.errors[:base], I18n.t('chapters.alerts.licensed')
    end

    test 'a draft cannot go live once the fiction is licensed' do
      chapter = Chapter.new(user: @user)
      persist(chapter, intent: 'draft')
      license!

      assert_not persist(chapter, intent: 'publish')
      assert_predicate chapter.reload, :draft?
    end

    test 'a released chapter can still be corrected' do
      chapter = Chapter.new(user: @user)
      persist(chapter, intent: 'publish')
      license!

      assert persist(chapter, intent: 'publish', title: 'Виправлена назва')
      assert_equal 'Виправлена назва', chapter.reload.title
    end

    test 'a released chapter cannot be scheduled into the future' do
      chapter = Chapter.new(user: @user)
      persist(chapter, intent: 'publish')
      license!

      assert_not persist(chapter, intent: 'publish', published_at: 2.days.from_now)
      assert_not_predicate chapter.reload, :scheduled?
    end

    private

    def license!
      @fiction.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')
    end

    def persist(chapter, intent:, **overrides)
      Persist.call(chapter:, attributes: attributes.merge(overrides), intent:, user: @user)
    end

    def attributes
      {
        content: 'x' * 500,
        fiction_id: @fiction.id,
        number: 88,
        scanlator_ids: [scanlators(:one).id.to_s],
        title: 'Persist chapter'
      }
    end
  end
end
