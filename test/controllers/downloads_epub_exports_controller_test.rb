# frozen_string_literal: true

require 'test_helper'

class DownloadsEpubExportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:user_one)
    @rich_text = action_text_rich_texts(:rich_text_four)
    @dummy_file_path = Rails.root.join('tmp/dummy.epub')
    FileUtils.touch(@dummy_file_path)
    sign_in @user
  end

  test 'should return ready export status with download url' do
    export_request = ready_export_request

    get "/downloads/epub_exports/#{export_request.token}/status"

    response_body = response.parsed_body

    assert_response :success
    assert_equal 'ready', response_body['status']
    assert_includes response_body['download_url'], export_request.token
  end

  test 'should redirect ready export file to attached blob' do
    export_request = ready_export_request

    get "/downloads/epub_exports/#{export_request.token}/file"

    assert_response :redirect
    assert_includes response.location, '/rails/active_storage/blobs'
  end

  test 'should block export file before it is ready' do
    export_request = EpubExportRequest.create!(user: @user, rich_text_ids: [@rich_text.id])

    get "/downloads/epub_exports/#{export_request.token}/file"

    assert_redirected_to 'http://www.example.com/'
    assert_equal I18n.t('downloads.alerts.forbidden'), flash[:alert]
  end

  test 'should block export status for another user' do
    export_request = ready_export_request
    sign_in users(:user_two)

    get "/downloads/epub_exports/#{export_request.token}/status"

    assert_redirected_to 'http://www.example.com/'
    assert_equal I18n.t('downloads.alerts.forbidden'), flash[:alert]
  end

  test 'should require login for export status' do
    export_request = ready_export_request
    sign_out @user

    get "/downloads/epub_exports/#{export_request.token}/status",
        headers: { 'Accept' => 'application/json' }

    assert_response :unauthorized
  end

  private

  def ready_export_request
    export_request = EpubExportRequest.create!(
      user: @user,
      rich_text_ids: [@rich_text.id],
      status: :ready,
      filename: 'generated_book.epub'
    )
    attach_dummy_epub(export_request)
    export_request
  end

  def attach_dummy_epub(export_request)
    File.open(@dummy_file_path) do |file|
      export_request.file.attach(
        io: file,
        filename: 'generated_book.epub',
        content_type: 'application/epub+zip'
      )
    end
  end
end
