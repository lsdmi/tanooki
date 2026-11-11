# frozen_string_literal: true

require 'test_helper'

module Meta
  class OpenGraphHelperTest < ActionView::TestCase
    include Meta::TagsHelper
    include Rails.application.routes.url_helpers

    test 'meta_type returns website for scanlator profile pages' do
      @scanlator = scanlators(:one)
      request.path = scanlator_path(@scanlator)

      assert_equal 'website', meta_type
    end

    test 'meta_twitter_card uses summary for scanlator profiles' do
      @scanlator = scanlators(:one)
      request.path = scanlator_path(@scanlator)

      assert_equal 'summary', meta_twitter_card
    end

    test 'meta_twitter_card uses summary_large_image for fiction pages' do
      request.path = fiction_path(fictions(:one))

      assert_equal 'summary_large_image', meta_twitter_card
    end
  end
end
