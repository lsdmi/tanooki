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

    test 'show does not render writings promo row' do
      get fiction_genre_fictions_url(genres(:one).slug)

      assert_response :success
      assert_select '.fiction-genre-writings-banner', count: 0
      assert_select '[aria-label="Писальня та сховище"]', count: 0
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
