# frozen_string_literal: true

require 'test_helper'

module Chapters
  class ContentLimitsTest < ActiveSupport::TestCase
    test 'accepts normal html content' do
      html = "<p>#{'word ' * 200}</p>"

      assert_empty ContentLimits.errors_for(html)
    end

    test 'rejects body larger than max bytes' do
      html = 'x' * (ContentLimits::MAX_BODY_BYTES + 1)

      errors = ContentLimits.errors_for(html)

      assert_equal [[:body_too_large, { max_mb: 2 }]], errors
    end

    test 'rejects inline data uri larger than max encoded bytes' do
      encoded = Base64.strict_encode64('x' * 350.kilobytes)
      html = %(<p><img src="data:image/png;base64,#{encoded}"></p>)

      errors = ContentLimits.errors_for(html)

      assert_includes errors.map(&:first), :inline_image_too_large
    end

    test 'accepts inline data uri below max encoded bytes' do
      encoded = Base64.strict_encode64('x' * 50.kilobytes)
      html = %(<p><img src="data:image/png;base64,#{encoded}"></p>)

      assert_empty ContentLimits.errors_for(html)
    end
  end
end
