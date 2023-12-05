# frozen_string_literal: true

require 'test_helper'

class YoutubeVideosHelperTest < ActionView::TestCase
  include YoutubeVideosHelper

  test 'split_tags should return an array of tags' do
    video = OpenStruct.new(tags: 'tag1, tag2, tag3')
    result = split_tags(video)

    assert_equal ['tag1', 'tag2', 'tag3'], result
  end
end
