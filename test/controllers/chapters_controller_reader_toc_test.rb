# frozen_string_literal: true

require 'test_helper'

class ChaptersControllerReaderTocTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  TRIGGER = 'button[data-chapter-drawer-target=trigger][aria-controls=reader-chapter-list-panel]'
  TOOLBAR_TRIGGER = "header.reader-toolbar #{TRIGGER}".freeze
  PHONE_TRIGGER = "#{TRIGGER}[data-jump-to-top-target=reveal][hidden]".freeze

  test 'the toolbar opens the chapter list with a visible Зміст label' do
    sign_in users(:user_one)
    get chapter_url(chapters(:one))

    assert_select "#{TOOLBAR_TRIGGER} span", text: I18n.t('chapters.reader_chapter_drawer.toc')
  end

  test 'phones get a Зміст button that stays outside the hiding toolbar' do
    sign_in users(:user_one)
    get chapter_url(chapters(:one))

    assert_select PHONE_TRIGGER, text: I18n.t('chapters.reader_chapter_drawer.toc')
    assert_select "header.reader-toolbar #{PHONE_TRIGGER}", count: 0
  end

  test 'guests get both Зміст buttons' do
    get chapter_url(chapters(:one))

    assert_select TRIGGER, count: 2
  end
end
