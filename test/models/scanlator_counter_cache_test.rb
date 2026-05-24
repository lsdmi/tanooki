# frozen_string_literal: true

require 'test_helper'

class ScanlatorCounterCacheTest < ActiveSupport::TestCase
  test 'fictions_count and members_count reflect associations' do
    scanlator = scanlators(:one)

    assert_equal scanlator.fiction_scanlators.count, scanlator.fictions_count
    assert_equal scanlator.scanlator_users.count, scanlator.members_count
  end

  test 'creating fiction_scanlator increments fictions_count' do
    scanlator = scanlators(:two)
    fiction = fictions(:one)

    assert_difference -> { scanlator.reload.fictions_count }, 1 do
      FictionScanlator.create!(fiction:, scanlator:)
    end
  end
end
