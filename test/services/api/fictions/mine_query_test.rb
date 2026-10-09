# frozen_string_literal: true

require 'test_helper'

module Api
  module Fictions
    class MineQueryTest < ActiveSupport::TestCase
      test 'returns fictions of the callers teams and the latest chapter number' do
        rows = MineQuery.call(users(:user_one))
        fiction = rows.find { |row| row[:id] == fictions(:one).id }

        assert_equal fictions(:one).title, fiction[:title]
        assert_equal 2, fiction[:teams].first[:last_chapter_number]
        assert_nil(rows.find { |row| row[:id] == fictions(:eighteen).id })
      end

      test 'the title query skips other titles' do
        rows = MineQuery.call(users(:user_one), query: 'Test Fiction 2')

        assert_equal [fictions(:two).id], rows.pluck(:id)
      end

      test 'another teams fiction is absent even for an admin' do
        FictionScanlator.create!(fiction: fictions(:eighteen), scanlator: scanlators(:two))
        rows = MineQuery.call(users(:user_one))

        assert_nil(rows.find { |row| row[:id] == fictions(:eighteen).id })
      end
    end
  end
end
