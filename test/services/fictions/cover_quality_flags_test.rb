# frozen_string_literal: true

require 'test_helper'

module Fictions
  class CoverQualityFlagsTest < ActiveSupport::TestCase
    include CoverUploadHelper

    test 'flags fictions with weak covers' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)

      FastImage.stub(:size, [500, 700]) do
        flags = CoverQualityFlags.for_fictions([fiction])

        assert_equal 1, flags.size
        assert_predicate flags[fiction.id], :fail?
      end
    end

    test 'skips fictions with ok covers' do
      fiction = fictions(:one)
      fiction.cover.attach(valid_cover_upload)

      FastImage.stub(:size, [600, 800]) do
        flags = CoverQualityFlags.for_fictions([fiction])

        assert_empty flags
      end
    end
  end
end
