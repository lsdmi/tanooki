# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/downloads_epub_test_case'

class DownloadsControllerTest < ActionDispatch::IntegrationTest
  include DownloadsEpubTestCase

  test 'should require login for single chapter epub export' do
    sign_out @user

    assert_no_difference('EpubExportRequest.count') do
      Books::GenerateEpubJob.stub :perform_later, ->(*) { flunk 'EPUB export should not be enqueued' } do
        get epub_download_path(id: @rich_text), headers: { 'Accept' => 'application/json' }
      end
    end

    assert_response :unauthorized
  end

  test 'should enqueue single chapter epub export job' do
    enqueued_id = nil

    assert_difference('EpubExportRequest.count') do
      enqueued_id = enqueue_single_epub_export
    end

    export_request = EpubExportRequest.last

    assert_response :accepted
    assert_equal export_request.id, enqueued_id
  end

  test 'should persist single chapter epub export details' do
    enqueue_single_epub_export
    export_request = EpubExportRequest.last

    assert_equal [@rich_text.id], export_request.rich_text_ids
    assert_equal @user.id, export_request.user_id
  end

  test 'should return single chapter epub export polling status' do
    enqueue_single_epub_export
    response_body = response.parsed_body

    assert_equal 'queued', response_body['status']
    assert_includes response_body['status_url'], EpubExportRequest.last.token
  end

  test 'should enqueue multiple chapters epub export job' do
    enqueued_id = nil

    assert_difference('EpubExportRequest.count') do
      enqueued_id = enqueue_multiple_epub_export
    end

    export_request = EpubExportRequest.last

    assert_response :accepted
    assert_equal export_request.id, enqueued_id
  end

  test 'should persist multiple chapters epub export details' do
    enqueue_multiple_epub_export
    export_request = EpubExportRequest.last

    assert_equal [3, 4], export_request.rich_text_ids.sort
    assert_equal 'Том 1', export_request.volume_title
  end

  test 'should handle error and redirect' do
    EpubExportRequest.stub :create!, ->(*) { raise StandardError } do
      get epub_download_path(id: @rich_text)
    end

    assert_redirected_to 'http://www.example.com/'
    assert_equal I18n.t('downloads.alerts.error'), flash[:alert]
  end
end
