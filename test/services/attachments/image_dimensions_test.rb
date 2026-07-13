# frozen_string_literal: true

require 'test_helper'

module Attachments
  class ImageDimensionsTest < ActiveSupport::TestCase
    include CoverUploadHelper

    test 'reads dimensions from analyzed blob metadata' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)
      fiction.cover.blob.update!(metadata: { 'width' => 600, 'height' => 800, 'analyzed' => true })

      assert_equal [600, 800], ImageDimensions.from_blob(fiction.cover.blob)
    end

    test 'falls back to fast image when metadata is missing' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)
      fiction.cover.blob.update!(metadata: {})

      FastImage.stub(:size, [640, 960]) do
        assert_equal [640, 960], ImageDimensions.from_blob(fiction.cover.blob)
      end
    end
  end
end
