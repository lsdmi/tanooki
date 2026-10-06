# frozen_string_literal: true

require 'test_helper'

class FictionPresentationTest < ActiveSupport::TestCase
  test 'similar_fictions lists other works with chapters' do
    fictions(:two).update!(chapter_count: 1)

    similar = fictions(:one).similar_fictions

    assert_includes similar, fictions(:two)
    assert_not_includes similar, fictions(:one)
  end
end
