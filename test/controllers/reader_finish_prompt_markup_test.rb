# frozen_string_literal: true

require 'test_helper'

# P3.4: the latest chapter offers «Прочитано» after this visit completes it. The page only renders the hidden prompt.
class ReaderFinishPromptMarkupTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  PROMPT = 'section[data-controller=reader-finish-prompt][hidden]'

  setup do
    @user = users(:user_one)
    @latest = chapters(:two)
  end

  test 'the latest chapter carries a hidden prompt that posts status finished' do
    sign_in @user
    get chapter_url(@latest)

    assert_select "#{PROMPT}[data-reader-finish-prompt-chapter-url-value=?]", record_progress_chapter_path(@latest)
    assert_select "#{PROMPT} form[action=?] input[name=status][value=finished]",
                  update_status_fiction_reading_progress_path(@latest.fiction)
  end

  test 'no prompt before the latest chapter, for guests, or once the library says finished' do
    sign_in @user
    get chapter_url(chapters(:one))

    assert_select PROMPT, count: 0

    reading_progresses(:one).update!(status: :finished)
    get chapter_url(@latest)

    assert_select PROMPT, count: 0

    sign_out @user
    get chapter_url(@latest)

    assert_select PROMPT, count: 0
  end
end
