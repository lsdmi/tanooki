# frozen_string_literal: true

require 'test_helper'

module Books
  class PurgeExpiredEpubExportsJobTest < ActiveSupport::TestCase
    test 'perform removes expired epub export requests' do
      EpubExportRequest.create!(
        user: users(:user_one),
        rich_text_ids: [action_text_rich_texts(:rich_text_four).id],
        expires_at: 1.hour.ago
      )
      EpubExportRequest.create!(
        user: users(:user_one),
        rich_text_ids: [action_text_rich_texts(:rich_text_four).id],
        expires_at: 1.hour.from_now
      )

      assert_difference('EpubExportRequest.count', -1) do
        PurgeExpiredEpubExportsJob.perform_now
      end
    end
  end
end
