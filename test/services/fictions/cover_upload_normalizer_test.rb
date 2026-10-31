# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CoverUploadNormalizerTest < ActiveSupport::TestCase
    include CoverUploadHelper

    test 'keeps webp bytes and uses a neutral filename' do
      upload = valid_cover_upload
      normalized = CoverUploadNormalizer.call(upload)

      assert_equal 'image/webp', normalized.content_type
      assert_equal 'cover.webp', normalized.original_filename
      assert_equal upload.size, normalized.size
    end

    test 'returns upload unchanged when blank' do
      assert_nil CoverUploadNormalizer.call(nil)
    end

    test 'converts png to webp when libvips is available' do
      skip 'libvips not installed' unless Attachments::VariantProcessing.available?

      upload = valid_png_cover_upload
      normalized = CoverUploadNormalizer.call(upload)

      assert_equal 'image/webp', normalized.content_type
      assert_equal 'cover.webp', normalized.original_filename
      assert_operator normalized.size, :>, 0
    end

    test 'replaces russian upload filenames with a neutral name' do
      path = CoverUploadHelper::VALID_COVER_PATH
      upload = Rack::Test::UploadedFile.new(path, 'image/webp')
      upload.define_singleton_method(:original_filename) { 'Новый холст.png' }

      normalized = CoverUploadNormalizer.call(upload)

      assert_equal 'cover.webp', normalized.original_filename
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
