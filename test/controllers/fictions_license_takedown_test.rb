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
    @fiction.update!(licensed_at: 2.days.ago, license_publisher: 'Видавництво Тест', license_url: STORE_URL)
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
    assert_select '.accordion #license-hidden-range', text: /Розділи 7–8 · приховано\s*\(ліцензія\)\s+2/
    assert_select '#chapters-list a[href=?]', chapter_path(@hidden), count: 0
  end

  test 'the chapters tab header and jump field name the preview range' do
    get fiction_url(@fiction)

    assert_select '#fiction-panel-chapters p', text: 'Ознайомчий фрагмент: розділи 1–6'
    assert_select '#chapter_list_progress', text: /решта приховані через ліцензію/
    assert_select '#chapter-jump-input[placeholder=?]', 'Перейти до розділу (1–6)…'
  end

  test 'the preview group is titled as the preview' do
    get fiction_url(@fiction)

    assert_select '.accordion-header h3', text: 'Ознайомчий фрагмент · Розділи 1–6'
  end

  test 'a reader past the preview gets the official edition as the only read button' do
    reading_progresses(:one).update!(chapter: @hidden, resume_at: Time.current, status: :active)
    sign_in users(:user_one)

    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions a[href=?]', STORE_URL, text: /#{I18n.t('fictions.license.read_official')}/
    assert_select '#fiction-hero-actions a[href^="/chapters/"]', count: 0
  end

  test 'a reader inside the preview also reads on from the official edition in the hero' do
    reading_progresses(:one).update!(chapter: chapters(:one), resume_at: Time.current, status: :active)
    sign_in users(:user_one)

    get fiction_url(@fiction)

    assert_select '#fiction-hero-actions a[href=?]', STORE_URL, text: /#{I18n.t('fictions.license.read_official')}/
    assert_select '#fiction-hero-actions a[href^="/chapters/"]', count: 0
  end

  test 'jumping to a hidden chapter says it is hidden' do
    get chapter_jump_fiction_url(@fiction, order: :asc, number: '7')

    assert_equal 'Розділ 7 приховано через ліцензію', response.parsed_body['error']
  end

  test 'the hero counts the available chapters and the notice leaves the preview to the tab' do
    get fiction_url(@fiction)

    assert_includes response.body, '6 з 8 розділів доступно'
    assert_not_includes response.body, 'доступні як ознайомчий фрагмент'
  end

  test 'a reader past the preview sees where they stopped before the license' do
    reading_progresses(:one).update!(chapter: @hidden, resume_at: Time.current, status: :active)
    sign_in users(:user_one)

    get fiction_url(@fiction)

    assert_includes response.body, 'Ви прочитали до розділу 7 до ліцензування.'
    assert_select 'a[href^=?]', chapter_path(@hidden), count: 0
  end

  test 'guests get no guest continue button on a licensed work' do
    get fiction_url(@fiction)

    assert_select '[data-controller~="guest-continue"]', count: 0
  end

  test 'after the admin takedown the page opens on About with the removed state' do
    @fiction.update!(chapters_hidden_at: Time.current)

    get fiction_url(@fiction)

    assert_select '#fiction-tab-about[aria-selected="true"]'
    assert_select '#license-removed', text: /#{I18n.t('fictions.license.removed.body')}/
    assert_select 'a[href=?]', STORE_URL, text: /#{I18n.t('fictions.license.read_official')}/, minimum: 2
  end

  test 'after the admin takedown the preview is gone too and the hero counts none' do
    @fiction.update!(chapters_hidden_at: Time.current)

    get chapter_url(chapters(:one))

    assert_select '#license-hidden'

    get fiction_url(@fiction)

    assert_includes response.body, '0 з 8 розділів доступно'
  end

  test 'a licensed work with nothing released says so instead of blaming the rights holder' do
    @fiction.chapters.destroy_all

    get fiction_url(@fiction)

    assert_select '#license-removed', text: /#{I18n.t('fictions.license.removed.body_unreleased')}/
    assert_not_includes response.body, 'на прохання правовласника'
  end

  test 'unmarking brings every chapter back' do
    @fiction.update!(licensed_at: nil, license_publisher: nil, license_url: nil)

    get chapter_url(@hidden)

    assert_select '#user-content'
  end
end
