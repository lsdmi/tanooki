# frozen_string_literal: true

require 'test_helper'

module Fictions
  class GenresControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get show for valid genre slug' do
      genre = genres(:one)

      get fiction_genre_fictions_url(genre.slug)

      assert_response :success
      assert_template :show
    end

    test 'show renders writings promo for guest without legacy ads' do
      get fiction_genre_fictions_url(genres(:one).slug)

      assert_select '[id^="advertisement-banner-"]', count: 0
      assert_select '.fiction-genre-writings-banner a[href="/login"]', text: /Увійти та почати писати/
      assert_select '.fiction-genre-writings-banner span', text: 'Для авторів'
    end

    test 'show writings promo links to studio for signed-in user' do
      genre = genres(:one)
      sign_in users(:user_one)

      get fiction_genre_fictions_url(genre.slug)

      assert_response :success
      assert_select '.fiction-genre-writings-banner a[href="/readings"]', text: /Відкрити писальню/
    end

    test 'should assign genre and skeleton on show' do
      genre = genres(:one)

      get fiction_genre_fictions_url(genre.slug)

      assert_equal genre, assigns(:genre)
      assert_instance_of FictionGenrePageSkeleton, assigns(:skeleton)
    end

    test 'should respond not found for unknown genre slug' do
      get fiction_genre_fictions_url('no-such-genre-slug')

      assert_response :not_found
    end
  end
end
