# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressInlineImagesJobTest < ActiveSupport::TestCase
    test 'perform delegates to CompressInlineImages' do
      expected = CompressInlineImages::Result.new(
        chapter_id: 1,
        rich_text_id: 3,
        images_compressed: 0,
        before_bytes: 100,
        after_bytes: 100,
        unchanged: true
      )

      CompressInlineImages.stub(:call, expected) do
        result = CompressInlineImagesJob.perform_now(1)

        assert_equal expected, result
      end
    end
  end
end
