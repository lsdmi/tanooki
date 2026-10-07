# frozen_string_literal: true

require 'test_helper'

class FictionsControllerShowLicensedTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  STORE_URL = 'https://starylev.com.ua/book'

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
  end

  test 'guests see the licensed notice with the publisher and a store link' do
    license!(url: STORE_URL)

    get fiction_url(@fiction)

    assert_response :success
    assert_includes response.body, I18n.t('fictions.notice_zone.licensed.body_with_publisher',
                                          publisher: 'Видавництво Тест')
    assert_select 'a[href=?][target="_blank"][rel="noopener noreferrer"]', STORE_URL, count: 3
  end

  test 'the hero shows the licensed tag instead of the listing state' do
    license!

    get fiction_url(@fiction)

    assert_select 'span', text: I18n.t('fictions.license.label')
    assert_select 'span', text: @fiction.listing_state_label, count: 0
  end

  test 'the about sidebar opens with the official edition card' do
    license!(url: STORE_URL)

    get fiction_url(@fiction)

    assert_select 'aside > section:first-child#official-edition-card' do
      assert_select 'span', text: 'Видавництво Тест'
      assert_select 'a[href=?]', STORE_URL, text: I18n.t('fictions.license.card.link')
    end
  end

  test 'without a store URL there are no official edition links' do
    license!

    get fiction_url(@fiction)

    assert_select '#official-edition-card'
    assert_select 'a', text: I18n.t('fictions.license.official_edition'), count: 0
  end

  test 'an unlicensed fiction has no licensed surfaces' do
    get fiction_url(@fiction)

    assert_select '#official-edition-card', count: 0
    assert_not_includes response.body, I18n.t('fictions.notice_zone.licensed.title')
  end

  test 'the reader shows a compact licensed banner above the chapter' do
    license!(url: STORE_URL)

    get chapter_url(chapters(:one))

    assert_select '#license-banner', text: /#{I18n.t('fictions.notice_zone.licensed.title')}/
    assert_select '#license-banner a[href=?][target="_blank"]', STORE_URL
  end

  test 'the reader of an unlicensed fiction has no banner' do
    get chapter_url(chapters(:one))

    assert_response :success
    assert_select '#license-banner', count: 0
  end

  private

  def license!(url: nil)
    @fiction.update!(licensed_at: 2.days.ago, license_publisher: 'Видавництво Тест', license_url: url)
  end
end
