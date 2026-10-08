# frozen_string_literal: true

require 'test_helper'

module Fictions
  class TitleLookupTest < ActiveSupport::TestCase
    test 'searches indexed title fields' do
      captured = {}
      Fiction.stub(:search, lambda { |query, **options|
        captured = { query:, options: }
        []
      }) do
        TitleLookup.new('  осеней ').call
      end

      assert_equal 'осеней', captured[:query]
      assert_equal(
        { fields: TitleLookup::FIELDS, limit: TitleLookup::LIMIT, where: { active: true } },
        captured[:options].slice(:fields, :limit, :where)
      )
    end

    test 'skips a query that is too short' do
      Fiction.stub(:search, ->(*) { raise 'search called' }) do
        assert_empty TitleLookup.new('я').call
      end
    end

    test 'returns nothing when search is unavailable' do
      Fiction.stub(:search, ->(*) { raise Searchkick::MissingIndexError, 'missing' }) do
        assert_empty TitleLookup.new('осеней').call
      end
    end
  end
end
