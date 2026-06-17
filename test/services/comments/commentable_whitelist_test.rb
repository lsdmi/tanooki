# frozen_string_literal: true

require 'test_helper'

module Comments
  class CommentableWhitelistTest < ActiveSupport::TestCase
    test 'allows known commentable types' do
      %w[Chapter Fiction Publication Tale YoutubeVideo].each do |type|
        assert CommentableWhitelist.allowed?(type)
      end
    end

    test 'rejects unknown commentable types' do
      %w[User TranslationRequest Scanlator].each do |type|
        assert_not CommentableWhitelist.allowed?(type)
      end
    end
  end
end
