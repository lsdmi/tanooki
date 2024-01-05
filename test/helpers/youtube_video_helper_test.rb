# frozen_string_literal: true

require 'test_helper'

class YoutubeVideosHelperTest < ActionView::TestCase
  include YoutubeVideosHelper

  TagsStruct = Struct.new(:tags)

  test 'split_tags should return an array of tags' do
    video = TagsStruct.new('tag1, tag2, tag3')
    result = split_tags(video)

    assert_equal %w[tag1 tag2 tag3], result
  end
end
