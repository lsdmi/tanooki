# frozen_string_literal: true

require 'test_helper'

class ScanlatorsShowCatalogTest < ActionDispatch::IntegrationTest
  test 'show renders works catalog chrome' do
    scanlator = scanlators(:one)
    get scanlator_path(scanlator)

    assert_response :success
    assert_kind_of Scanlators::ShowPresenter, assigns(:scanlator_stats)
    assert_select "##{Scanlators::WorksCatalogHelper::WORKS_FRAME_ID}"
  end

  test 'show uses fading team banner strip and avatar alt' do
    scanlator = scanlators(:one)
    get scanlator_path(scanlator)

    assert_select '.scanlator-show__banner img', count: 1
    assert_select 'img[alt=?]', scanlator.title
  end

  test 'show lists member avatars without a links heading' do
    get scanlator_path(scanlators(:one))

    assert_select 'ul[aria-label="Учасники"] a[href=?]', profile_path(users(:user_one).sqid)
    assert_select 'p', text: 'Посилання', count: 0
  end

  test 'show stats include chapter count and rating' do
    get scanlator_path(scanlators(:one))

    assert_includes response.body, 'Розділів'
    assert_includes response.body, '4.5'
  end

  test 'show defaults works sort to popularity' do
    get scanlator_path(scanlators(:one))

    assert_select '#scanlator-sort-button', text: /Популярні/
  end

  test 'show filters works by search query' do
    get scanlator_path(scanlators(:one), q: 'Test Fiction')

    assert_includes assigns(:fictions).map(&:title), 'Test Fiction'
  end

  test 'show search with no matches returns an empty works list' do
    get scanlator_path(scanlators(:one), q: 'zzzz-no-match')

    assert_empty assigns(:fictions)
  end

  test 'show switches to list view' do
    get scanlator_path(scanlators(:one), view: 'list')

    assert_select 'article.flex.gap-4', minimum: 1
  end

  test 'show works turbo frame returns catalog partial' do
    get scanlator_path(scanlators(:one)),
        headers: { 'Turbo-Frame' => Scanlators::WorksCatalogHelper::WORKS_FRAME_ID }

    assert_select "turbo-frame##{Scanlators::WorksCatalogHelper::WORKS_FRAME_ID}"
    assert_select 'input[name=q]'
  end
end
