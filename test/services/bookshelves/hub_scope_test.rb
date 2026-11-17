# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class HubScopeTest < ActiveSupport::TestCase
    setup do
      @viewer = users(:user_one)
      @owner = users(:user_two)
      @everyone = fictions(:one)
      @eighteen = fictions(:eighteen)
      @foreign = @owner.bookshelves.create!(
        title: 'Only eighteen shelf',
        description: 'All works are 18+ for hub filter tests',
        fiction_ids: [@eighteen.id]
      )
      BookshelfFiction.create!(bookshelf: @foreign, fiction: @eighteen)
    end

    test 'open filter keeps every shelf' do
      ids = HubScope.relation(viewer: @viewer, filter: ContentFilters::Preference.open).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'active filter drops another reader shelf with no visible works' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @viewer, filter:).pluck(:id)

      assert_not_includes ids, @foreign.id
    end

    test 'active filter keeps a shelf that still has a visible work' do
      BookshelfFiction.create!(bookshelf: @foreign, fiction: @everyone)
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @viewer, filter:).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'owner still sees their own all-hidden shelf' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @owner, filter:).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'guest with active filter also drops all-hidden shelves' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: nil, filter:).pluck(:id)

      assert_not_includes ids, @foreign.id
    end
  end
end
