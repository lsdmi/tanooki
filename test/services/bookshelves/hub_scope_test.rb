# frozen_string_literal: true

require 'test_helper'

module Bookshelves
  class HubScopeTest < ActiveSupport::TestCase
    setup do
      @viewer = users(:user_one)
      @owner = users(:user_two)
      @everyone = fictions(:one)
      @teen = fictions(:two)
      @eighteen = fictions(:eighteen)
      @foreign = @owner.bookshelves.create!(
        title: 'Only eighteen shelf',
        description: 'All works are 18+ for hub filter tests',
        fiction_ids: [@eighteen.id]
      )
      replace_shelf_fictions!(@foreign, [@eighteen, @eighteen, @eighteen])
    end

    test 'open filter keeps shelves with enough works' do
      ids = HubScope.relation(viewer: @viewer, filter: ContentFilters::Preference.open).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'open filter drops shelves below the minimum' do
      thin = @owner.bookshelves.create!(
        title: 'Thin hub shelf xx',
        description: 'Only two works so the hub should hide this shelf',
        fiction_ids: [@everyone.id, @teen.id]
      )
      replace_shelf_fictions!(thin, [@everyone, @teen])

      ids = HubScope.relation(viewer: @viewer, filter: ContentFilters::Preference.open).pluck(:id)

      assert_not_includes ids, thin.id
    end

    test 'active filter drops another reader shelf with too few visible works' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @viewer, filter:).pluck(:id)

      assert_not_includes ids, @foreign.id
    end

    test 'active filter keeps a shelf that still has enough visible works' do
      mild = @everyone.dup
      mild.title = 'Hub mild third work'
      mild.slug = nil
      mild.content_rating = :everyone
      mild.save!(validate: false)
      replace_shelf_fictions!(@foreign, [@everyone, @teen, mild])
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @viewer, filter:).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'owner still sees their own sized shelf when the filter hides its works' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: @owner, filter:).pluck(:id)

      assert_includes ids, @foreign.id
    end

    test 'guest with active filter also drops all-hidden shelves' do
      filter = ContentFilters::Preference.new(max_rating: 16)
      ids = HubScope.relation(viewer: nil, filter:).pluck(:id)

      assert_not_includes ids, @foreign.id
    end

    private

    def replace_shelf_fictions!(bookshelf, fictions)
      BookshelfFiction.where(bookshelf:).delete_all
      fictions.each_with_index { |fiction, index| add_shelf_fiction!(bookshelf, fiction, index) }
    end

    def add_shelf_fiction!(bookshelf, fiction, index)
      return BookshelfFiction.create!(bookshelf:, fiction:) unless BookshelfFiction.exists?(bookshelf:, fiction:)

      clone = fiction.dup
      clone.title = "Hub scope pad #{bookshelf.id}-#{index}"
      clone.slug = nil
      clone.save!(validate: false)
      BookshelfFiction.create!(bookshelf:, fiction: clone)
    end
  end
end
