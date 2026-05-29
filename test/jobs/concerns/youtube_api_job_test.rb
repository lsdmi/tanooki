# frozen_string_literal: true

require 'test_helper'

class YoutubeApiJobTest < ActiveSupport::TestCase
  test 'VideosJob includes YoutubeApiJob' do
    assert_includes Youtube::VideosJob.ancestors, YoutubeApiJob
  end

  test 'VideosJob includes ExternalApiResilience via YoutubeApiJob' do
    assert_includes Youtube::VideosJob.ancestors, ExternalApiResilience
  end
end
