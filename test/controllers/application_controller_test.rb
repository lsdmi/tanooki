# frozen_string_literal: true

require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @controller = ApplicationController.new
    @expected_video_urls = [
      'https://www.youtube.com/embed/video1',
      'https://www.youtube.com/embed/video2'
    ]
  end

  test 'returns an array of up to three YouTube video URLs from the most recent ActionText rich text entries' do
    assert_equal @expected_video_urls, @controller.send(:videos)
  end
end
