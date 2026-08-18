# frozen_string_literal: true

require 'test_helper'

module Books
  class PurgeExpiredEpubExportsTest < ActiveSupport::TestCase
    test 'call removes expired epub export requests' do
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

      result = nil
      assert_difference('EpubExportRequest.count', -1) do
        result = PurgeExpiredEpubExports.call
      end

      assert_equal 1, result.purged
      assert_empty result.errors
    end
  end
end
