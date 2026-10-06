# frozen_string_literal: true

require 'test_helper'

class FictionsControllerShowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    sign_in users(:user_one)
    @fiction = fictions(:one)
  end

  test 'toggle_order from reader drawer updates reader drawer turbo frame' do
    chapter = chapters(:one)

    post toggle_order_fiction_path(@fiction, order: :desc, reader_drawer: true, current_chapter_id: chapter.id),
         headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

    assert_response :success
    assert_includes response.body, 'turbo-stream action="update" target="sort-chapters-reader-drawer"'
    assert_includes response.body, 'toggle-fictions-order-drawer'
  end

  test 'show renders translator support card shell' do
    @fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
    Rails.cache.delete("fiction_#{@fiction.id}")

    get fiction_url(@fiction)

    assert_response :success
    assert_select 'aside section[aria-labelledby="fiction-support-title"] ' \
                  'a[href="https://send.monobank.ua/jar/example"][target="_blank"]'
  end

  test 'show chapter order toggle uses fictions-order-toggle stimulus controller' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '#toggle-fictions-order[data-controller="fictions-order-toggle"]'
    assert_select '#toggle-fictions-order[data-action="click->fictions-order-toggle#spin"]'
  end

  test 'show support card uses shared reader copy' do
    @fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
    Rails.cache.delete("fiction_#{@fiction.id}")

    get fiction_url(@fiction)

    assert_includes response.body, I18n.t('chapters.reader_support_card.title')
    assert_includes response.body, I18n.t('chapters.reader_support_card.support', service: 'monobank')
  end

  test 'show uses resized cover in the hero when variants are available' do
    skip 'libvips not installed' unless Attachments::VariantProcessing.available?

    get fiction_url(@fiction)

    assert_response :success
    assert_select 'section[aria-labelledby="fiction-title"] picture source[type="image/avif"]'
    assert_select 'section[aria-labelledby="fiction-title"] picture ' \
                  'img[src*="representations"][fetchpriority="high"][loading="eager"]', count: 1
  end

  test 'hero backdrop reuses the cover image instead of preloading a separate background' do
    skip 'libvips not installed' unless Attachments::VariantProcessing.available?

    get fiction_url(@fiction)

    assert_response :success
    assert_select 'link[rel="preload"][as="image"]', count: 0
    cover_sources = css_select('section[aria-labelledby="fiction-title"] picture img').pluck('src')

    assert_equal [cover_sources.first] * 2, cover_sources
  end

  test 'show does not load reader-only google fonts' do
    get fiction_url(@fiction)

    assert_response :success
    assert_not_includes response.body, 'fonts.googleapis.com'
  end

  test 'show includes chapters accordion with toggle actions' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '[data-controller="chapters-accordion"]'
    assert_select '.accordion-header[data-action*="chapters-accordion#toggle"]'
  end

  test 'hero chapter count is the live count even when expected is larger' do
    @fiction.update!(chapter_count: 160, expected_chapters: 2334, last_chapter_at: 3.days.ago)

    get fiction_url(@fiction)

    assert_response :success
    assert_select 'section[aria-labelledby="fiction-title"] li', text: '160 розділів'
    assert_select 'section[aria-labelledby="fiction-title"]', text: /2334/, count: 0
  end

  test 'hero chapter count is the live count when expected is unknown' do
    @fiction.update!(chapter_count: 307, expected_chapters: nil, last_chapter_at: nil)

    get fiction_url(@fiction)

    assert_response :success
    assert_select 'section[aria-labelledby="fiction-title"] li', text: '307 розділів'
  end

  test 'a finished fiction shows the finished notice instead of the add-chapter CTA' do
    @fiction.update!(completed_at: Time.current)

    get fiction_url(@fiction)

    assert_not_includes response.body, 'Додайте нові розділи!'
    assert_select 'section[aria-labelledby="fiction-title"] [role="note"]', text: /ПЕРЕКЛАД ЗАВЕРШЕНО/
    assert_not_includes response.body, 'Ранобе завершено!'
  end

  test 'a stale fiction shows the no-new-chapters notice under a 16+ notice' do
    @fiction.update!(content_rating: :sixteen, chapter_count: 3, last_chapter_at: 4.months.ago, completed_at: nil)

    get fiction_url(@fiction)

    titles = css_select('section[aria-labelledby="fiction-title"] [role="note"] p.font-semibold').map(&:text)

    assert_equal ['Контент 16+', 'НОВИХ РОЗДІЛІВ НЕМАЄ ПОНАД 3 МІСЯЦІ'], titles
  end

  test 'an ongoing everyone-rated fiction shows no notices' do
    @fiction.update!(content_rating: :everyone, chapter_count: 3, last_chapter_at: 1.day.ago, completed_at: nil)

    get fiction_url(@fiction)

    assert_select '[role="note"]', count: 0
  end
end
