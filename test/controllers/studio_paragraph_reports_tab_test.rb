# frozen_string_literal: true

require 'test_helper'

class StudioParagraphReportsTabTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @report = ParagraphReport.create!(
      user: users(:user_two),
      chapter: chapters(:one),
      block_index: 0,
      quote: 'Цитата для Studio',
      digest: 'f' * ParagraphReport::DIGEST_LENGTH,
      message: 'Тут калька'
    )
    sign_in users(:user_one)
  end

  test 'notifications tab lists open paragraph reports with resolve actions' do
    get studio_index_path(tab: 'notifications')

    assert_response :success
    assert_select '#studio-paragraph-reports-heading', text: /Повідомлення про помилки/
    assert_select 'blockquote', text: /Цитата для Studio/
  end

  test 'notifications tab exposes a fixed action for the open report' do
    get studio_index_path(tab: 'notifications')

    assert_select 'form[action=?]', studio_paragraph_report_path(@report, status: 'fixed')
  end

  test 'notifications tab links out to the reader and editor' do
    get studio_index_path(tab: 'notifications')

    assert_select 'a', text: 'У рідері'
    assert_select 'a', text: 'Редагувати'
    assert_select 'p', text: /Тут калька/
  end

  test 'a foreign team member does not see the report' do
    FictionScanlator.create!(fiction: fictions(:two), scanlator: scanlators(:two))
    sign_in users(:user_two)

    get studio_index_path(tab: 'notifications')

    assert_response :success
    assert_select 'blockquote', text: /Цитата для Studio/, count: 0
    assert_select '#studio-paragraph-reports-heading', count: 0
  end

  test 'a reader without a team does not see the paragraph reports section' do
    reader = users(:user_two)
    reader.scanlator_users.destroy_all
    sign_in reader

    get studio_index_path(tab: 'notifications')

    assert_response :success
    assert_select '#studio-paragraph-reports-heading', count: 0
    assert_select 'blockquote', text: /Цитата для Studio/, count: 0
  end

  test 'duplicate reports on the same block are grouped' do
    ParagraphReport.create!(
      user: users('user_101'),
      chapter: chapters(:one),
      block_index: 0,
      quote: 'Цитата для Studio',
      digest: @report.digest,
      message: 'Другий читач'
    )

    get studio_index_path(tab: 'notifications')

    assert_response :success
    assert_select 'blockquote', text: /Цитата для Studio/, count: 1
    assert_select 'span', text: /2 читач/
  end
end
