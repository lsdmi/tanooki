# frozen_string_literal: true

require 'test_helper'

class ChaptersAuthorMetaTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
  end

  test 'show exposes author meta from fiction for crawlers' do
    sign_in users(:user_one)
    get chapter_url(@chapter)

    fiction = @chapter.fiction

    assert_select 'meta[name="author"][content=?]', fiction.author
    published_at = (@chapter.published_at || @chapter.created_at).iso8601

    assert_select 'meta[property="article:published_time"][content=?]', published_at
    assert_select 'meta[property="article:modified_time"][content=?]', @chapter.updated_at.iso8601
  end

  test 'show exposes Article JSON-LD with same author' do
    sign_in users(:user_one)
    get chapter_url(@chapter)

    article_ld = article_ld_from_response

    assert_equal 'Article', article_ld['@type']

    assert_equal @chapter.fiction.author, article_ld.dig('author', 'name')

    expected_author_url = search_index_url(
      search: [@chapter.fiction.author],
      only_path: false,
      **Rails.application.config.action_mailer.default_url_options.symbolize_keys
    )

    assert_equal expected_author_url, article_ld.dig('author', 'url')
  end

  private

  def article_ld_from_response
    response.body.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).filter_map do |(fragment)|
      parsed = JSON.parse(fragment)
      parsed if parsed['@type'] == 'Article'
    rescue JSON::ParserError
      nil
    end.first
  end
end
