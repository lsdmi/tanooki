# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/downloads_epub_test_case'

class DownloadsEpubPermissionControllerTest < ActionDispatch::IntegrationTest
  include DownloadsEpubTestCase

  test 'should block single chapter epub when scanlator disallows conversion' do
    with_scanlator_conversion_disabled do
      Books::GenerateEpubJob.stub :perform_later, ->(*) { flunk 'EPUB export should not be enqueued' } do
        get epub_download_path(id: @rich_text)
      end
    end

    assert_redirected_to 'http://www.example.com/'
    assert_equal I18n.t('downloads.alerts.forbidden'), flash[:alert]
  end

  test 'should block multiple chapters epub when any scanlator disallows conversion' do
    with_scanlator_conversion_disabled do
      Books::GenerateEpubJob.stub :perform_later, ->(*) { flunk 'EPUB export should not be enqueued' } do
        get epub_multiple_downloads_path(chapter_ids: [1, 2], volume_title: 'Том 1')
      end
    end

    assert_redirected_to 'http://www.example.com/'
    assert_equal I18n.t('downloads.alerts.forbidden'), flash[:alert]
  end
end
