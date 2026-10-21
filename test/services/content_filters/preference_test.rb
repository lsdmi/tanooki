# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class PreferenceTest < ActiveSupport::TestCase
    setup do
      @everyone = fictions(:one)
      @sixteen = fictions(:two)
      @eighteen = fictions(:eighteen)
      FictionGenre.create!(fiction: @sixteen, genre: genres(:two))
      FictionGenre.create!(fiction: @eighteen, genre: genres(:two))
    end

    test 'open keeps every band' do
      preference = Preference.open

      assert_not_predicate preference, :active?
      assert_equal({}, preference.searchkick_where)
      assert_equal [@everyone.id, @sixteen.id, @eighteen.id], listed_ids(preference)
    end

    test 'an open fingerprint is the literal open' do
      assert_equal 'open', Preference.open.fingerprint
    end

    test 'a rating of 16 drops 18+ only' do
      preference = Preference.new(max_rating: 16, hidden_genre_ids: [].freeze)

      assert_equal [@everyone.id, @sixteen.id], listed_ids(preference)
      assert_equal({ content_rating: { lte: 16 } }, preference.searchkick_where)
    end

    test 'a rating of 0 drops 16+ and 18+' do
      preference = Preference.new(max_rating: 0, hidden_genre_ids: [].freeze)

      assert_equal [@everyone.id], listed_ids(preference)
      assert_equal({ content_rating: { lte: 0 } }, preference.searchkick_where)
    end

    test 'hidden genres drop matching works and ignore id order in the fingerprint' do
      forward = Preference.new(max_rating: nil, hidden_genre_ids: [genres(:one).id, genres(:two).id])
      reverse = Preference.new(max_rating: nil, hidden_genre_ids: [genres(:two).id, genres(:one).id])

      assert_equal [], listed_ids(forward)
      assert_equal forward.fingerprint, reverse.fingerprint
      assert_equal({ _not: { genre_ids: [genres(:one).id, genres(:two).id] } }, forward.searchkick_where)
    end

    test 'rating and genres compose' do
      preference = Preference.new(max_rating: 16, hidden_genre_ids: [genres(:two).id])

      assert_equal [@everyone.id], listed_ids(preference)
      assert_equal(
        { content_rating: { lte: 16 }, _not: { genre_ids: [genres(:two).id] } },
        preference.searchkick_where
      )
    end

    private

    def listed_ids(preference)
      preference.apply(Fiction.where(id: [@everyone.id, @sixteen.id, @eighteen.id])).order(:id).pluck(:id)
    end
  end
end
