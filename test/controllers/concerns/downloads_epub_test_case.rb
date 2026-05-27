# frozen_string_literal: true

module DownloadsEpubTestCase
  extend ActiveSupport::Concern

  included do
    include Devise::Test::IntegrationHelpers

    setup do
      @user = users(:user_one)
      @rich_text = action_text_rich_texts(:rich_text_four)
      sign_in @user
    end
  end

  private

  def assert_cached_epub_enqueue_response(export_request)
    assert_response :ok
    body = response.parsed_body

    assert body['cached']
    assert_equal 'ready', body['status']
    assert_includes body['download_url'], export_request.token
  end

  def enqueue_single_epub_export
    enqueued_id = nil
    Books::GenerateEpubJob.stub(:perform_later, ->(id) { enqueued_id = id }) do
      get epub_download_path(id: @rich_text), headers: { 'Accept' => 'application/json' }
    end
    enqueued_id
  end

  def enqueue_multiple_epub_export
    enqueued_id = nil
    Books::GenerateEpubJob.stub(:perform_later, ->(id) { enqueued_id = id }) do
      get epub_multiple_downloads_path(chapter_ids: [1, 2], volume_title: 'Том 1'),
          headers: { 'Accept' => 'application/json' }
    end
    enqueued_id
  end

  def with_scanlator_conversion_disabled
    scanlator = scanlators(:one)
    scanlator.update!(convertable: false, member_ids: scanlator.user_ids)
    yield scanlator
  ensure
    scanlator&.update!(convertable: true, member_ids: scanlator.user_ids)
  end
end
