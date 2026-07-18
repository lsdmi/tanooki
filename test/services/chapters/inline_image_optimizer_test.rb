# frozen_string_literal: true

require 'test_helper'

module Chapters
  class InlineImageOptimizerTest < ActiveSupport::TestCase
    test 'uses higher max edge and jpeg quality than epub export defaults' do
      assert_operator InlineImageOptimizer::MAX_EDGE, :>, Books::EpubDataUriImageOptimizer::MAX_EDGE
      assert_operator InlineImageOptimizer::JPEG_QUALITY, :>, Books::EpubDataUriImageOptimizer::JPEG_QUALITY
    end

    test 'optimize_data_uri_in_html forwards chapter settings to epub optimizer' do
      html = '<img src="data:image/png;base64,abc">'
      called = {}

      Books::EpubDataUriImageOptimizer.stub(
        :optimize_data_uri_in_html,
        lambda { |h, start, finish, max_edge:, jpeg_quality:|
          called.merge!(html: h, start: start, finish: finish, max_edge: max_edge, jpeg_quality: jpeg_quality)
          %w[jpeg jpg]
        }
      ) do
        InlineImageOptimizer.optimize_data_uri_in_html(html, 10, 40)
      end

      assert_equal(
        { html: html, start: 10, finish: 40, max_edge: InlineImageOptimizer::MAX_EDGE,
          jpeg_quality: InlineImageOptimizer::JPEG_QUALITY },
        called
      )
    end
  end
end
