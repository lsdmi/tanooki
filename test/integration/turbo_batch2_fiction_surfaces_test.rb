# frozen_string_literal: true

require 'test_helper'

class TurboBatch2FictionSurfacesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'alphabetical fiction list details escape turbo frame for fiction show' do
    get alphabetical_fictions_url

    assert_response :success
    assert_select 'turbo-frame#fiction_details_frame a[data-turbo-frame="_top"][href*="/fictions/"]'
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_fiction_details_frame_html)
  end

  test 'fictions index hot updates escape turbo frame for fiction show' do
    get fictions_url

    assert_response :success
    assert_select 'turbo-frame#fiction_details a[data-turbo-frame="_top"][href*="/fictions/"]'
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_hot_updates_html)
  end

  test 'fiction show details browse links use Turbo Drive' do
    sign_in users(:user_one)
    fiction = fictions(:one)

    Rails.cache.delete("fiction_#{fiction.id}")
    get fiction_url(fiction)

    assert_response :success
    assert_no_match(/turbo:\s*false|data-turbo="false"/, extract_fiction_details_section_html)
    assert_select '.fiction-details a[data-turbo-frame="_top"][href*="/scanlators/"]'
  end

  test 'fiction details turbo stream replaces details without flash frame streams' do
    fiction = fictions(:two)

    get details_fiction_url(fiction, format: :turbo_stream)

    assert_response :success
    assert_select 'turbo-stream[action="replace"][target="fiction_details"]', count: 1
    assert_no_match(/target="application-notice"/, response.body)
  end

  private

  def extract_fiction_details_frame_html
    response.body[%r{turbo-frame[^>]*id="fiction_details_frame"[^>]*>.*?</turbo-frame>}m] || ''
  end

  def extract_hot_updates_html
    response.body[%r{turbo-frame[^>]*id="fiction_details"[^>]*>.*?</turbo-frame>}m] || ''
  end

  def extract_fiction_details_section_html
    response.body[%r{class="fiction-details.*?</div>\s*</div>\s*</div>}m] || ''
  end
end
