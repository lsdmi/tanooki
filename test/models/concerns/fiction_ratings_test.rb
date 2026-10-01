# frozen_string_literal: true

require 'test_helper'

class FictionRatingsTest < ActiveSupport::TestCase
  setup do
    @fiction = fictions(:one)
    @user = users(:user_one)
  end

  test 'average_rating computes correctly from preloaded association' do
    fiction = Fiction.includes(:fiction_ratings).find(@fiction.id)

    assert_in_delta 4.5, fiction.average_rating
  end

  test 'average_rating computes correctly without preload' do
    assert_in_delta 4.5, @fiction.average_rating
  end

  test 'average_rating returns zero when there are no ratings' do
    fiction = fictions(:two)

    assert_in_delta 0.0, fiction.average_rating
  end

  test 'rating_count uses preloaded association without extra queries' do
    fiction = Fiction.includes(:fiction_ratings).find(@fiction.id)

    assert_queries_count(0) { assert_equal 2, fiction.rating_count }
  end

  test 'average_rating uses preloaded association without extra queries' do
    fiction = Fiction.includes(:fiction_ratings).find(@fiction.id)

    assert_queries_count(0) { assert_in_delta 4.5, fiction.average_rating }
  end

  test 'user_rating uses preloaded association without extra queries' do
    fiction = Fiction.includes(:fiction_ratings).find(@fiction.id)

    assert_queries_count(0) { assert_equal 4, fiction.user_rating(@user) }
  end

  test 'rating_summary returns count and average in one query' do
    fiction = Fiction.find(@fiction.id)

    assert_queries_count(1) { assert_equal [2, 4.5], fiction.rating_summary }
  end

  test 'rating_summary uses preloaded association without extra queries' do
    fiction = Fiction.includes(:fiction_ratings).find(@fiction.id)

    assert_queries_count(0) { assert_equal [2, 4.5], fiction.rating_summary }
  end

  test 'rating_summary is zero for a fiction without ratings' do
    assert_equal [0, 0.0], fictions(:two).rating_summary
  end

  test 'average_rating issues database queries when association is not preloaded' do
    fiction = Fiction.find(@fiction.id)

    assert_queries_count(2) { assert_in_delta 4.5, fiction.average_rating }
  end
end
