# frozen_string_literal: true

require 'test_helper'

class TalesAuthorMetaTest < ActionDispatch::IntegrationTest
  setup do
    @tale = publications(:tale_approved_one)
  end

  test 'show exposes author name and article:author for crawlers' do
    Publication.stub :search, Publication.all do
      get tale_url(@tale)

      expected_author_url = Rails.application.routes.url_helpers.profile_url(
        @tale.user.sqid,
        only_path: false,
        **Rails.application.config.action_mailer.default_url_options.symbolize_keys
      )

      assert_select 'meta[name="author"][content=?]', @tale.username
      assert_select 'meta[property="article:author"][content=?]', expected_author_url
    end
  end

  test 'show exposes article published and modified times in open graph' do
    Publication.stub :search, Publication.all do
      get tale_url(@tale)

      assert_select 'meta[property="article:published_time"][content=?]', @tale.created_at.iso8601
      assert_select 'meta[property="article:modified_time"][content=?]', @tale.updated_at.iso8601
    end
  end

  test 'show NewsArticle JSON-LD author includes profile url' do
    Publication.stub :search, Publication.all do
      get tale_url(@tale)

      expected_author_url = Rails.application.routes.url_helpers.profile_url(
        @tale.user.sqid,
        only_path: false,
        **Rails.application.config.action_mailer.default_url_options.symbolize_keys
      )

      article_ld = news_article_ld_from_response

      assert_equal expected_author_url, article_ld.dig('author', 'url')
      assert_equal @tale.username, article_ld.dig('author', 'name')
    end
  end

  private

  def news_article_ld_from_response
    response.body.scan(%r{<script type="application/ld\+json">\s*(.*?)\s*</script>}m).filter_map do |(fragment)|
      parsed = JSON.parse(fragment)
      parsed if parsed['@type'] == 'NewsArticle'
    rescue JSON::ParserError
      nil
    end.first
  end
end
