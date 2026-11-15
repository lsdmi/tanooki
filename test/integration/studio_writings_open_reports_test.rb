# frozen_string_literal: true

require 'test_helper'

class StudioWritingsOpenReportsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    ParagraphReport.create!(
      user: users(:user_two),
      chapter: chapters(:one),
      block_index: 0,
      quote: 'Цитата для писальні',
      digest: 'e' * ParagraphReport::DIGEST_LENGTH
    )
    ParagraphReport.create!(
      user: users('user_101'),
      chapter: chapters(:one),
      block_index: 1,
      quote: 'Друга цитата',
      digest: 'f' * ParagraphReport::DIGEST_LENGTH
    )
    sign_in users(:user_one)
  end

  test 'writings tab shows open paragraph report counts per fiction' do
    label = I18n.t('chapters.paragraph_reports.studio_label', count: 2)
    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_select '[aria-label=Статистика] [title=?]', label, text: /2/
    assert_select '[aria-label=Статистика] [role=tooltip]', text: label
  end

  test 'writings tab hides open report counts when there are none' do
    ParagraphReport.open.delete_all

    get studio_index_path(tab: 'writings')

    assert_response :success
    assert_select '[aria-label=Статистика]'
    assert_select '.text-status-warning-subtle-fg', count: 0
  end
end
