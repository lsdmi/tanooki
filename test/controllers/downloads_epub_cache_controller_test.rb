# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/downloads_epub_test_case'

class DownloadsEpubCacheControllerTest < ActionDispatch::IntegrationTest
  include DownloadsEpubTestCase

  test 'reuses ready export for same user and chapters without enqueueing job' do
    existing = EpubExportRequest.create!(
      user: @user,
      rich_text_ids: [@rich_text.id],
      status: :ready,
      filename: 'cached.epub'
    )
    existing.file.attach(
      io: StringIO.new('epub'),
      filename: 'cached.epub',
      content_type: 'application/epub+zip',
      identify: false
    )

    assert_no_difference('EpubExportRequest.count') do
      Books::GenerateEpubJob.stub :perform_later, ->(*) { flunk 'should not enqueue when cache hit' } do
        get epub_download_path(id: @rich_text), headers: { 'Accept' => 'application/json' }
      end
    end

    assert_cached_epub_enqueue_response(existing)
  end
end
