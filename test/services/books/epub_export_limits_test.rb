# frozen_string_literal: true

require 'test_helper'

module Books
  class EpubExportLimitsTest < ActiveSupport::TestCase
    test 'too_large? compares summed rich text body bytes' do
      rich_text = action_text_rich_texts(:rich_text_four)

      assert_not EpubExportLimits.too_large?([rich_text.id])

      Books::EpubExportLimits.stub(:source_bytes, Books::EpubExportLimits::MAX_SOURCE_BYTES + 1) do
        assert Books::EpubExportLimits.too_large?([rich_text.id])
      end
    end
  end
end
