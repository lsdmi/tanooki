# frozen_string_literal: true

require 'test_helper'

module TelegramDigests
  class PostTest < ActiveSupport::TestCase
    test 'call dispatches known digests' do
      called = nil
      YoutubeVideos.stub(:call, -> { called = :youtube }) do
        Post.call('youtube')
      end

      assert_equal :youtube, called
    end

    test 'call raises for unknown digests' do
      assert_raises(ArgumentError) { Post.call('nope') }
    end
  end
end
