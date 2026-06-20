# frozen_string_literal: true

require 'test_helper'

class TurboBatch3ChapterReaderTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'chapter reader navigation uses Turbo Drive with preload' do
    sign_in users(:user_one)
    chapter = chapters(:two)

    get chapter_url(chapter)

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_reader_nav_html)

    chapter_nav_selector = '.reader-chapter-nav a[data-turbo-frame="_top"]' \
                           '[data-turbo-preload="true"][href*="/chapters/"]'

    assert_select chapter_nav_selector, minimum: 1
  end

  test 'chapter reader anchor card fiction link uses Turbo Drive' do
    sign_in users(:user_one)
    chapter = chapters(:one)

    get chapter_url(chapter)

    assert_response :success
    assert_select '.reader-anchor-card a[data-turbo-frame="_top"][href*="/fictions/"]'
  end

  test 'chapter reader drawer fiction links use Turbo Drive' do
    sign_in users(:user_one)
    chapter = chapters(:one)

    get chapter_url(chapter)

    assert_response :success
    assert_select '#reader-chapter-list-panel a[data-turbo-frame="_top"][href*="/fictions/"]', minimum: 1
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_reader_bottom_html)
  end

  test 'readings chapter list escapes turbo frame for chapter reader' do
    sign_in users(:user_one)
    fiction = fictions(:one)

    get reading_url(fiction)

    assert_response :success
    assert_select 'turbo-frame#chapters-list a[data-turbo-frame="_top"][href*="/chapters/"]'
  end

  private

  def extract_reader_nav_html
    response.body[%r{class="reader-chapter-nav.*?</nav>}m] || ''
  end

  def extract_reader_bottom_html
    response.body[%r{class="reader-bottom-card.*?</section>}m] || ''
  end
end
