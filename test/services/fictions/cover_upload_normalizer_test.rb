# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CoverUploadNormalizerTest < ActiveSupport::TestCase
    include CoverUploadHelper

    test 'returns upload unchanged for webp' do
      upload = valid_cover_upload

      assert_equal upload, CoverUploadNormalizer.call(upload)
    end

    test 'returns upload unchanged when blank' do
      assert_nil CoverUploadNormalizer.call(nil)
    end

    test 'converts png to webp when libvips is available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      upload = valid_png_cover_upload
      normalized = CoverUploadNormalizer.call(upload)

      assert_equal 'image/webp', normalized.content_type
      assert_equal 'test_cover_valid.webp', normalized.original_filename
      assert_operator normalized.size, :>, 0
    end

    test 'raises when png cannot be converted without libvips' do
      Attachments::VariantProcessing.stub(:available?, false) do
        upload = valid_png_cover_upload

        assert_raises(CoverUploadNormalizer::Error) do
          CoverUploadNormalizer.call(upload)
        end
      end
    end
  end
end
