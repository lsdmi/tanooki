# frozen_string_literal: true

require 'test_helper'

class FictionsLicenseTakedownTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  STORE_URL = 'https://starylev.com.ua/book'

  setup do
    @fiction = fictions(:one)
    @fiction.scanlator_ids = @fiction.scanlators.ids
    (3..8).each do |number|
      Chapter.create!(fiction: @fiction, user: users(:user_one), title: "Chapter #{number}", number:,
                      content: 'x' * 500, scanlator_ids: [scanlators(:one).id])
    end
    @fiction.update!(licensed_at: 2.days.ago, license_publisher: 'Видавництво Тест', license_url: STORE_URL,
                     chapters_hidden_at: 1.day.ago)
    @hidden = @fiction.chapters.find_by(number: 7)
  end

  test 'a hidden chapter answers with the interstitial instead of its text' do
    get chapter_url(@hidden)

    assert_select '#license-hidden', text: /#{I18n.t('chapters.license_hidden.title')}/
    assert_select '#user-content', count: 0
    assert_select 'meta[name="robots"][content="noindex, follow"]'
  end

  test 'a hidden chapter keeps its comments and a preview chapter still reads' do
    get chapter_url(@hidden)

    assert_select '#reader-comments-panel'

    get chapter_url(chapters(:one))

    assert_select '#user-content'
  end

  test 'the chapters tab lists the preview with the hidden bar and range row' do
    get fiction_url(@fiction)

    assert_select '#license-hidden-bar', text: /Розділи 7–8 приховані через офіційну ліцензію/
    assert_select '#license-hidden-range', text: /Розділи 7–8 · приховано \(ліцензія\), не видалено\s+2/
    assert_select '#chapters-list a[href=?]', chapter_path(@hidden), count: 0
  end

  test 'jumping to a hidden chapter says it is hidden' do
    get chapter_jump_fiction_url(@fiction, order: :asc, number: '7')

    assert_equal 'Розділ 7 приховано через ліцензію', response.parsed_body['error']
  end

  test 'the hero counts the available chapters and the notice names the preview' do
    get fiction_url(@fiction)

    assert_includes response.body, '6 з 8 розділів доступно'
    assert_includes response.body, 'Розділи 1–6 доступні як ознайомчий фрагмент, решта приховані.'
  end

  test 'a reader past the preview sees where they stopped before the license' do
    reading_progresses(:one).update!(chapter: @hidden, resume_at: Time.current, status: :active)
    sign_in users(:user_one)

    get fiction_url(@fiction)

    assert_includes response.body, 'Ви прочитали до розділу 7 до ліцензування.'
  end

  test 'with nothing left to read the page opens on About with the removed state' do
    @fiction.chapters.destroy_all

    get fiction_url(@fiction)

    assert_select '#fiction-tab-about[aria-selected="true"]'
    assert_select '#license-removed', text: /#{I18n.t('fictions.license.removed.title')}/
    assert_select 'a[href=?]', STORE_URL, text: /#{I18n.t('fictions.license.read_official')}/, minimum: 2
  end
end
