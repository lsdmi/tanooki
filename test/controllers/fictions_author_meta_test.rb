# frozen_string_literal: true

require 'test_helper'

class FictionsAuthorMetaTest < ActionDispatch::IntegrationTest
  setup do
    @fiction = fictions(:one)
  end

  test 'show exposes author byline and meta tags for crawlers' do
    get fiction_url(@fiction)

    author_href = search_index_path(search: [@fiction.author])
    expected_author_url = Rails.application.routes.url_helpers.search_index_url(
      search: [@fiction.author],
      only_path: false,
      **Rails.application.config.action_mailer.default_url_options.symbolize_keys
    )

    assert_select 'p.author a[rel=?][href=?]', 'author', author_href, text: @fiction.author
    assert_select 'meta[name="author"][content=?]', @fiction.author
    assert_select 'meta[property="article:author"][content=?]', expected_author_url
  end

  test 'show Book JSON-LD includes author with url' do
    get fiction_url(@fiction)

    expected_author_url = Rails.application.routes.url_helpers.search_index_url(
      search: [@fiction.author],
      only_path: false,
      **Rails.application.config.action_mailer.default_url_options.symbolize_keys
    )

    book_ld = json_ld_type_from_response('Book')

    assert_equal @fiction.title, book_ld['name']
    assert_equal expected_author_url, book_ld.dig('author', 'url')
    assert_equal @fiction.author, book_ld.dig('author', 'name')
  end

  private

  def json_ld_type_from_response(type)
    response.body.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).filter_map do |(fragment)|
      parsed = JSON.parse(fragment)
      parsed if parsed['@type'] == type
    rescue JSON::ParserError
      nil
    end.first
  end
end
