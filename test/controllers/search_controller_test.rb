# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    client = Elasticsearch::Client.new
    index_name = 'publications_test'
    index_exists = client.indices.exists(index: index_name)
    Publication.reindex unless index_exists
    advertisements(:advertisement_one)
  end

  test 'should get index with search' do
    get search_index_url, params: { search: ['test'] }
    assert_response :success
  end

  test 'should redirect to root without search' do
    get search_index_url
    assert_redirected_to root_path
  end
end
