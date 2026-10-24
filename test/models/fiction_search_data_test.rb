# frozen_string_literal: true

require 'test_helper'

class FictionSearchDataTest < ActiveSupport::TestCase
  test 'search_data indexes the rating integer and genre ids' do
    data = fictions(:one).search_data

    assert_equal 0, data.fetch(:content_rating)
    assert_equal [genres(:one).id], data.fetch(:genre_ids)
  end
end
