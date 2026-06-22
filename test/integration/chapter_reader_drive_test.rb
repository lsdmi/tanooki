# frozen_string_literal: true

require 'test_helper'

class ChapterReaderDriveTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'chapter reader prev next nav enables turbo drive preload' do
    sign_in users(:user_one)

    get chapter_url(chapters(:two))

    assert_select '.reader-chapter-nav a[data-turbo-preload="true"][data-turbo-frame="_top"]', minimum: 1
  end

  test 'chapter reader nav omits turbo false' do
    sign_in users(:user_one)

    get chapter_url(chapters(:two))

    assert_no_match(/turbo:\s*false|data-turbo="false"/, reader_chapter_nav_html)
  end

  test 'chapter reader anchor card fiction link escapes frame' do
    sign_in users(:user_one)

    get chapter_url(chapters(:one))

    assert_select '.reader-anchor-card a[data-turbo-frame="_top"][href*="/fictions/"]'
  end

  test 'chapter drawer fiction links escape frame' do
    sign_in users(:user_one)

    get chapter_url(chapters(:one))

    assert_select '#reader-chapter-list-panel a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
  end

  test 'readings chapter list escapes frame for chapter reader' do
    sign_in users(:user_one)

    get reading_url(fictions(:one))

    assert_select 'turbo-frame#chapters-list a[data-turbo-frame="_top"][href*="/chapters/"]'
  end

  private

  def reader_chapter_nav_html
    response.body[%r{class="reader-chapter-nav.*?</nav>}m] || ''
  end
end
