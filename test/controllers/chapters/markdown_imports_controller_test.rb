# frozen_string_literal: true

require 'test_helper'

module Chapters
  class MarkdownImportsControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    setup do
      ActionController::Base.cache_store.clear
      @member = users(:user_two)
    end

    test 'a team member gets the converted and sanitized HTML' do
      sign_in @member

      markdown = "## Розділ\n\nМеча[^1] і <script>x</script>\n\n[^1]: Секта."
      post chapter_markdown_imports_url, params: { markdown: }, as: :json

      assert_response :success
      html = Nokogiri::HTML5.fragment(response.parsed_body['html'])

      assert_equal 'Секта.', html.at_css('h2 + p span.note-reference')['data-note']
      assert_includes html.text, '<script>x</script>'
    end

    test 'what the sanitizer removed comes back for the editor to show' do
      sign_in @member

      post chapter_markdown_imports_url, params: { markdown: 'Арт: ![x](https://evil.test/a.png)' }, as: :json

      assert_equal ['зображення з іншого сайту: https://evil.test/a.png'], response.parsed_body['changes']
    end

    test 'blank text is refused' do
      sign_in @member

      post chapter_markdown_imports_url, params: { markdown: "  \n" }, as: :json

      assert_response :unprocessable_content
      assert_equal I18n.t('chapters.markdown_imports.errors.blank'), response.parsed_body['error']
    end

    test 'text over the size limit is refused' do
      sign_in @member

      markdown = 'а' * ((MarkdownImportsController::MAX_BYTES / 2) + 1)
      post chapter_markdown_imports_url, params: { markdown: }, as: :json

      assert_response :content_too_large
    end

    test 'a user with no team cannot convert' do
      user = users('user_101')
      user.scanlator_users.delete_all
      sign_in user

      post chapter_markdown_imports_url, params: { markdown: '**так**' }, as: :json

      assert_response :forbidden
    end

    test 'guests are turned away' do
      post chapter_markdown_imports_url, params: { markdown: '**так**' }, as: :json

      assert_response :unauthorized
    end
  end
end
