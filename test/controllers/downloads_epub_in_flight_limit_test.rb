# frozen_string_literal: true

require 'test_helper'
require_relative 'concerns/downloads_epub_test_case'

class DownloadsEpubInFlightLimitTest < ActionDispatch::IntegrationTest
  include DownloadsEpubTestCase

  test 'a third export waits while two of the user\'s own are still building' do
    in_flight_exports(:queued, :processing)

    assert_no_difference('EpubExportRequest.count') do
      Books::GenerateEpubJob.stub :perform_later, ->(*) { flunk 'should not enqueue past the limit' } do
        get epub_download_path(id: @rich_text), headers: { 'Accept' => 'application/json' }
      end
    end

    assert_response :too_many_requests
    assert_equal 'waiting', response.parsed_body['status']
  end

  test 'other users\' exports do not count toward the limit' do
    in_flight_exports(:queued, :processing, user: users(:user_two))

    assert_difference('EpubExportRequest.count') { enqueue_single_epub_export }
    assert_response :accepted
  end

  test 'requests older than the stale window do not block their owner' do
    in_flight_exports(:queued, :queued).each { |export| export.update!(created_at: 31.minutes.ago) }

    assert_difference('EpubExportRequest.count') { enqueue_single_epub_export }
    assert_response :accepted
  end

  test 'an export already requested is still returned at the limit' do
    existing = EpubExportRequest.create!(user: @user, rich_text_ids: [@rich_text.id], status: :queued)
    in_flight_exports(:processing)

    assert_no_difference('EpubExportRequest.count') do
      get epub_download_path(id: @rich_text), headers: { 'Accept' => 'application/json' }
    end

    assert_response :accepted
    assert_includes response.parsed_body['status_url'], existing.token
  end

  private

  def in_flight_exports(*statuses, user: @user)
    statuses.each_with_index.map do |status, index|
      EpubExportRequest.create!(user:, rich_text_ids: [900_000 + index], status:, volume_title: "Том #{index}")
    end
  end
end
