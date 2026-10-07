# frozen_string_literal: true

require 'test_helper'

class LicensedFictionEpubAdsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    @fiction = @chapter.fiction
    @fiction.scanlator_ids = @fiction.scanlators.ids
    @fiction.update!(licensed_at: 2.days.ago, license_publisher: 'Видавництво Тест')
    Rails.cache.delete("fiction_#{@fiction.id}")
  end

  test 'the reader hides the EPUB button and the guest EPUB banner' do
    get chapter_url(@chapter)

    assert_select 'section.reader-epub-banner', count: 0

    sign_in users(:user_one)
    get chapter_url(@chapter)

    assert_select '[data-controller="epub-download"]', count: 0
  end

  test 'the fiction page hides the section EPUB buttons and the EPUB card' do
    sign_in users(:user_one)

    get fiction_url(@fiction)

    assert_select '[data-controller="epub-download"]', count: 0
    assert_not_includes response.body, I18n.t('fictions.about.epub.hint')
  end

  test 'a direct EPUB request is forbidden' do
    sign_in users(:user_one)

    assert_no_difference 'EpubExportRequest.count' do
      get epub_multiple_downloads_url, params: { chapter_ids: [@chapter.id] }, as: :json
    end
  end

  test 'production serves no ads on the fiction page or in the reader' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      get fiction_url(@fiction)

      assert_select 'body[data-load-adsense="false"]'

      get chapter_url(@chapter)

      assert_select 'body[data-load-adsense="false"]'
    end
  end

  test 'production still serves reader ads on an unlicensed fiction' do
    @fiction.update!(licensed_at: nil, license_publisher: nil)

    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      get chapter_url(@chapter)
    end

    assert_select 'body[data-load-adsense="true"]'
  end
end
