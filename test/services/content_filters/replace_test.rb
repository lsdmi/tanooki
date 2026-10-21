# frozen_string_literal: true

require 'test_helper'

module ContentFilters
  class ReplaceTest < ActiveSupport::TestCase
    test 'saves a rating cap and replaces hidden genres' do
      user = users(:user_two)
      result = Replace.call(user:, max_content_rating: '0', hidden_genre_ids: [genres(:three).id])

      assert_predicate result, :success?
      assert_equal 0, user.reload.content_filter.max_content_rating
      assert_equal [genres(:three).id], user.hidden_genres.pluck(:genre_id)
    end

    test 'a blank rating clears the cap and the genres' do
      user = users(:user_one)
      user.hidden_genres.create!(genre: genres(:one))

      result = Replace.call(user:, max_content_rating: '', hidden_genre_ids: [])

      assert_predicate result, :success?
      assert_nil user.reload.content_filter
      assert_empty user.hidden_genres
    end

    test 'an unknown rating writes nothing' do
      user = users(:user_one)

      result = Replace.call(user:, max_content_rating: '18', hidden_genre_ids: [genres(:one).id])

      assert_equal I18n.t('content_filters.errors.rating'), result.error
      assert_equal 16, user.reload.content_filter.max_content_rating
      assert_empty user.hidden_genres
    end

    test 'rejects a rating pill and more than thirty genres' do
      user = users(:user_one_one_zero)
      pill = Genre.create!(name: '18+', slug: 'eighteen-pill', description: 'Rating pill.')

      pill_result = Replace.call(user:, max_content_rating: '', hidden_genre_ids: [pill.id])
      cap_ids = Array.new(UserHiddenGenre::MAX_PER_USER + 1) { |index| create_genre(index).id }
      cap_result = Replace.call(user:, max_content_rating: '16', hidden_genre_ids: cap_ids)

      assert_equal I18n.t('content_filters.errors.genre'), pill_result.error
      assert_equal I18n.t('content_filters.errors.cap'), cap_result.error
      assert_nil user.reload.content_filter
    end

    private

    def create_genre(index)
      Genre.create!(name: "Вибір #{index}", slug: "choice-#{index}")
    end
  end
end
