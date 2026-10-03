# frozen_string_literal: true

require 'test_helper'

class FictionsContinueTranslationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @fiction = fictions(:one)
    @fiction.update!(completed_at: nil, chapter_count: 5,
                     last_chapter_at: FictionListingProgress::STALE_AFTER.ago - 1.day)
    @new_chapter = "/chapters/new?fiction=#{@fiction.slug}"
  end

  test 'another team can pick up a stale translation from the notice and the chapters tab' do
    sign_in users(:user_two)
    get fiction_url(@fiction)

    assert_select '[role="note"] a[href=?]', @new_chapter, text: 'Продовжити переклад'
    assert_select '#fiction-panel-chapters a[href=?]', @new_chapter, text: 'Додати розділ'
  end

  test 'the fiction team sees the notice action too' do
    sign_in users(:user_one)
    get fiction_url(@fiction)

    assert_select '[role="note"] a[href=?]', @new_chapter, text: 'Продовжити переклад'
  end

  test 'a guest is offered to log in from the notice' do
    get fiction_url(@fiction)

    assert_select '[role="note"] a[href^="/login"]', text: 'Увійдіть, щоб продовжити переклад'
  end

  test 'an ongoing translation has no notice action, only the chapters tab line' do
    @fiction.update!(last_chapter_at: 1.day.ago)
    sign_in users(:user_two)
    get fiction_url(@fiction)

    assert_select '[role="note"] a', count: 0
    assert_select '#fiction-panel-chapters a[href=?]', @new_chapter
  end
end
