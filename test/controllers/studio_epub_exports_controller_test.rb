# frozen_string_literal: true

require 'test_helper'

class StudioEpubExportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'epub exports route opens studio epub tab' do
    user = users(:user_one)
    sign_in user

    get epub_exports_path

    assert_redirected_to studio_index_path
    assert_equal 'epub_exports', session[:studio_tab]
  end

  test 'studio epub tab shows only current user exports' do
    user = users(:user_one)
    own_export = create_epub_export(user, 'own.epub')
    create_epub_export(users(:user_two), 'other.epub')
    sign_in user

    get studio_index_path(tab: 'epub_exports')

    assert_response :success
    assert_includes response.body, own_export.filename
    assert_not_includes response.body, 'other.epub'
  end

  private

  def create_epub_export(user, filename)
    EpubExportRequest.create!(
      user:,
      rich_text_ids: [action_text_rich_texts(:rich_text_four).id],
      status: :ready,
      filename:
    )
  end
end
