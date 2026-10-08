# frozen_string_literal: true

require 'test_helper'

class LicensedFictionListsTest < ActionDispatch::IntegrationTest
  include SearchControllerTesting

  setup do
    ActionController::Base.cache_store.clear
    @licensed = fictions(:two)
    @licensed.update!(licensed_at: 1.day.ago, license_publisher: 'Видавництво Тест')
  end

  test 'the alphabetical licensed filter lists only licensed works' do
    get alphabetical_fictions_url, params: { licensed: '1' }

    assert_select '[data-fiction-picker-id-param]', 1
    assert_select '[data-fiction-picker-id-param=?]', @licensed.id.to_s
  end

  test 'a cover picked on a filtered catalog URL keeps the catalog details' do
    get details_fiction_url(@licensed, format: :turbo_stream),
        headers: { 'HTTP_REFERER' => alphabetical_fictions_url(licensed: '1', page: 2) }

    assert_select 'turbo-stream[target="fiction_details"] #fiction_details.flex-row'
  end

  test 'search results still list a licensed work' do
    with_stubbed_tag_counts do
      with_stubbed_search(Fiction, Publication, YoutubeVideo) do
        get search_index_url, params: { search: [@licensed.title], filter: 'fiction' }
      end
    end

    assert_response :success
    assert_select 'turbo-frame#fictions-section a[href=?]', fiction_path(@licensed)
  end
end
