# frozen_string_literal: true

require 'test_helper'

module Layout
  class LayoutFragmentKeysHelperTest < ActionView::TestCase
    include LayoutFragmentKeysHelper

    test 'advertisement_banner_ready? rejects ads without attachments' do
      advertisement = Advertisement.new(resource: 'https://example.com')

      assert_not advertisement_banner_ready?(advertisement)
    end

    test 'advertisement_cover_label falls back when cover is missing' do
      advertisement = Advertisement.new

      assert_equal 'Реклама', advertisement_cover_label(advertisement)
    end
  end
end
