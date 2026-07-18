# frozen_string_literal: true

require 'test_helper'

module Chapters
  class CompressInlineImagesTest < ActiveSupport::TestCase
    test 'call updates chapter rich text body' do # rubocop:disable Minitest/MultipleAssertions
      rich_text = action_text_rich_texts(:rich_text_four)
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      rich_text.update_column(:body, %(<p><img src="data:image/png;base64,#{encoded}"></p>)) # rubocop:disable Rails/SkipsModelValidations
      jpeg = Base64.decode64(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
      )

      Chapters::InlineImageOptimizer.stub(:optimize_data_uri_in_html, [jpeg, 'jpg']) do
        Attachments::VariantProcessing.stub(:available?, true) do
          result = CompressInlineImages.call(chapters(:one).id)

          assert_equal 1, result.images_compressed
          assert_not result.unchanged
          body = rich_text.reload.read_attribute_before_type_cast(:body)

          assert_includes body, 'data:image/jpeg;base64,'
          assert_operator result.after_bytes, :<, result.before_bytes
        end
      end
    end
  end
end
