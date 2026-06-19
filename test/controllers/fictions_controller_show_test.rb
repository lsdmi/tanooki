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

    post toggle_order_fictions_path(id: @fiction.id, order: :desc, reader_drawer: true, current_chapter_id: chapter.id),
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
    assert_includes response.body, 'reader-support-card'
    assert_includes response.body, 'reader-outlined-btn'
  end

  test 'show support card uses shared reader copy' do
    @fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
    Rails.cache.delete("fiction_#{@fiction.id}")

    get fiction_url(@fiction)

    assert_includes response.body, I18n.t('chapters.reader_support_card.title')
    assert_includes response.body, I18n.t('chapters.reader_support_card.support')
  end

  test 'show uses resized cover in details when variants are available' do
    skip 'libvips not installed' unless Attachments::VariantProcessing.available?

    get fiction_url(@fiction)

    assert_response :success
    assert_select '.fiction-details img[src*="representations"]'
  end

  test 'show includes chapters accordion with toggle actions' do
    get fiction_url(@fiction)

    assert_response :success
    assert_select '[data-controller="chapters-accordion"]'
    assert_select '.accordion-header[data-action*="chapters-accordion#toggle"]'
  end

  test 'show support card does not use legacy hover animation classes' do
    @fiction.scanlators.first.update!(bank_url: 'https://send.monobank.ua/jar/example')
    Rails.cache.delete("fiction_#{@fiction.id}")

    get fiction_url(@fiction)

    assert_select '.reader-support-card [class*="hover:-translate-y-1"]', count: 0
  end
end
