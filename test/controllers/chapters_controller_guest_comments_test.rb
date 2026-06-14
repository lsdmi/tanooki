# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerGuestCommentsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @chapter = chapters(:one)
    @chapter.comments << comments(:comment_one)
    sign_out users(:user_one)
  end

  test 'guest sees login prompt in comments drawer when chapter has comments' do
    get chapter_url(@chapter)

    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.login_prompt')
    assert_includes response.body, I18n.t('chapters.reader_comments_drawer.login_to_comment')
  end

  test 'guest comments drawer links to login instead of empty state' do
    get chapter_url(@chapter)

    assert_not_includes response.body, Comments::Presentation.empty_state_for('chapters')
    assert_includes response.body, new_user_session_path
  end
end
